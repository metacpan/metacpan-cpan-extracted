use Test::More;
use IO::File;

use_ok 'Net::Bamboo';

my $bamboo = new Net::Bamboo;

isa_ok $bamboo, 'Net::Bamboo';

# set hostname (required)
$bamboo->hostname('www.fruits.com');

# add a handler that short-circuits our requests
$bamboo->_ua->add_handler(request_send => \&trap);

# this should cause a lazy fetch
cmp_ok $bamboo->num_projects, '==', 4, 'num_projects';

########################################################################
########################################################################

# test the project keys handler

{
	my @names = sort $bamboo->project_keys;

	cmp_ok scalar(@names), '==', 4, 'four project keys';

	is $names[0], CANTALOUPE	=> 'first project key';
	is $names[1], FRTBANANA		=> 'second project key';
	is $names[2], FRTKIWI		=> 'third project key';
	is $names[3], FRTORANGE		=> 'fourth project key';
}

########################################################################
########################################################################

# run the entire gamut of the API for the "Cantaloupe" project

{
	# test the project accessors and a sample project
	ok !$bamboo->project('CRAP'), 'non-existant project';

	my $project = $bamboo->project('CANTALOUPE');

	isa_ok $project, 'Net::Bamboo::Project', 'project CANTALOUPE';
	isa_ok $project->bamboo, 'Net::Bamboo', 'owner';
	is $project->key, 'CANTALOUPE', 'project key';
	is $project->name, 'Cantaloupe', 'project name';

	cmp_ok $project->num_plans, '==', 1, 'num_plans';

	# test the plan accessors and a sample plan
	ok !$project->plan('POOP'), 'non-existant plan';

	my $plan = $project->plan('DEFAULT');

	isa_ok $plan, 'Net::Bamboo::Plan', 'plan DEFAULT';
	isa_ok $plan->project, 'Net::Bamboo::Project', 'owner';
	is $plan->key, 'DEFAULT', 'plan key';
	is $plan->name, 'Default', 'plan name';
	cmp_ok $plan->num_stages, '==', '2', 'plan num_stages';
	ok $plan->is_enabled, 'plan is_enabled';
	ok !$plan->is_active, 'plan is_active';
	ok !$plan->is_building, 'plan is_building';

	is $plan->fqkey, 'CANTALOUPE-DEFAULT', 'plan fully-qualified key';

	# test the build accessors and a sample build
	ok !$plan->build('TURD'), 'non-existant build';
	ok !$plan->build(8), 'non-existant build';

	my $build = $plan->build(7);

	isa_ok $build, 'Net::Bamboo::Build', 'build #7';
	isa_ok $build->plan, 'Net::Bamboo::Plan', 'owner';
	is $build->key, 'CANTALOUPE-DEFAULT-7', 'build key';
	is $build->number, 7, 'build number';
	is $build->state, 'Successful', 'build state';
	isa_ok $build->date_started, 'DateTime', 'build date_started';
	isa_ok $build->date_completed, 'DateTime', 'build date_completed';
	cmp_ok $build->num_tests_ok, 'eq', 8, 'build num_tests_ok';
	cmp_ok $build->num_tests_fail, 'eq', 0, 'build num_tests_fail';
	ok $build->succeeded, 'build succeeded';
	ok !$build->failed, 'build failed';

	# test the latest_build accessor
	isa_ok $plan->latest_build, 'Net::Bamboo::Build', 'latest build';
	cmp_ok $plan->latest_build->number, '==', $build->number, 'latest build is #7';
}

########################################################################
########################################################################

# run the entire gamut of the API for the "Orange" project

{
	my $project = $bamboo->project('FRTORANGE');

	isa_ok $project, 'Net::Bamboo::Project', 'project FRTORANGE';
	isa_ok $project->bamboo, 'Net::Bamboo', 'owner';
	is $project->key, 'FRTORANGE', 'project key';
	is $project->name, 'Fruit Orange', 'project name';

	cmp_ok $project->num_plans, '==', 2, 'num_plans';

	# test the plan accessors and a sample plan
	ok !$project->plan('POOP'), 'non-existant plan';

	my $plan = $project->plan('DEFAULT');

	isa_ok $plan, 'Net::Bamboo::Plan', 'plan DEFAULT';
	isa_ok $plan->project, 'Net::Bamboo::Project', 'owner';
	is $plan->key, 'DEFAULT', 'plan key';
	is $plan->name, 'Master', 'plan name';
	cmp_ok $plan->num_stages, '==', '3', 'plan num_stages';
	ok $plan->is_enabled, 'plan is_enabled';
	ok !$plan->is_active, 'plan is_active';
	ok !$plan->is_building, 'plan is_building';

	is $plan->fqkey, 'FRTORANGE-DEFAULT', 'plan fully-qualified key';

	# test the build accessors and a sample build
	ok !$plan->build('TURD'), 'non-existant build';
	ok !$plan->build(8), 'non-existant build';

	my $build = $plan->build(69);

	isa_ok $build, 'Net::Bamboo::Build', 'build #7';
	isa_ok $build->plan, 'Net::Bamboo::Plan', 'owner';
	is $build->key, 'FRTORANGE-DEFAULT-69', 'build key';
	is $build->number, 69, 'build number';
	is $build->state, 'Failed', 'build state';
	isa_ok $build->date_started, 'DateTime', 'build date_started';
	isa_ok $build->date_completed, 'DateTime', 'build date_completed';
	cmp_ok $build->num_tests_ok, 'eq', 744, 'build num_tests_ok';
	cmp_ok $build->num_tests_fail, 'eq', 290, 'build num_tests_fail';
	ok !$build->succeeded, 'build succeeded';
	ok $build->failed, 'build failed';

	# test the latest_build accessor
	isa_ok $plan->latest_build, 'Net::Bamboo::Build', 'latest build';
	cmp_ok $plan->latest_build->number, '!=', $build->number, 'latest build is not #69';
}

done_testing;

# TODO: replace this fucktardery with a LWP::UserAgent test library that
#       doesn't suck jimmy kimmel's moldy balls in the dead of winter.

sub trap
{
	my $req = shift;
	my $res = undef;

	if ($req->uri eq 'http://www.fruits.com/rest/api/latest/project?os_authType=basic&expand=projects.project.plans.plan') {
		my $io = new IO::File;

		$io->open('t/projects');

		$res = HTTP::Response->parse(join '', $io->getlines);
	}

	if ($req->uri eq 'http://www.fruits.com/rest/api/latest/result/CANTALOUPE-DEFAULT?os_authType=basic&expand=results%5B0%3A5%5D.result') {
		my $io = new IO::File;

		$io->open('t/results-cantaloupe');

		$res = HTTP::Response->parse(join '', $io->getlines);
	}

	if ($req->uri eq 'http://www.fruits.com/rest/api/latest/result/FRTORANGE-DEFAULT?os_authType=basic&expand=results%5B0%3A5%5D.result') {
		my $io = new IO::File;

		$io->open('t/results-orange');

		$res = HTTP::Response->parse(join '', $io->getlines);
	}

	return $res;
}
