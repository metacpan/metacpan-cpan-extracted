#!/usr/bin/perl
use strict;
use vars qw($run_output);

use lib qw(t/lib);

use Test::More;

my $class  = 'Module::Release::Git';

use_ok( 'Local::Config' );
use_ok( 'Module::Release' );

subtest dummy_releaserc => sub {
	if( -e 'releaserc' ) { return pass( "releaserc exists" ) }
	my $fh;
	unless( open $fh, '>', 'releaserc' ) {
		return fail( "Could not create releaserc: $!" );
		}
	print { $fh } "cpan_user ADOPTME\n";
	pass( "Created releaserc" );
	};

my $release = Module::Release->new;
$release->load_mixin( $class );
can_ok( $release, qw(vcs_branch is_allowed_branch) );

{
package Module::Release;
no warnings qw(redefine once);
*run          = sub { $main::run_output = $_[1] };
*remote_file  = sub { $_[0]->{remote_file} };
*dist_version = sub { $_[0]->{dist_version} };
*_warn        = sub { 1 };
*_print       = sub { 1 };
*_get_time    = sub { '137' };
}

subtest branch => sub {
	no warnings qw(redefine);
	can_ok( $release, qw(vcs_branch) );
	no strict 'refs';

	local $Module::Release::run_output;
	local *{'Module::Release::run'} = sub { $Module::Release::run_output };

	subtest no_git => sub {
		# stderr would be 'fatal: Not a git repository (or any of the parent directories): .git'
		local $Module::Release::run_output = undef;
		ok( ! defined $release->run,        'run() output is not defined' );
		ok( ! defined $release->vcs_branch, 'vcs_branch() output is not defined' );
		};

	subtest master => sub {
		my $branch = 'master';
		local $Module::Release::run_output = $branch;
		is( $release->run,        $branch, "run() output is the right branch <$branch>" );
		is( $release->vcs_branch, $branch, "vcs_branch() output is <$branch>" );
		};

	};

subtest allowed_branch => sub {
	no warnings qw(redefine);
	can_ok( $release, qw(is_allowed_branch) );

	subtest no_config => sub {
		my $config_hash = {};
		my $config = Local::Config->new( $config_hash );
		no strict 'refs';
		local *{'Module::Release::config'} = sub { $config };
		can_ok( $release, 'config' );
		isa_ok( $release->config, 'Local::Config' );

		ok( ! defined $release->config->allowed_branches,       'allowed_branches is not configured' );
		ok( ! defined $release->config->allowed_branches_regex, 'allowed_branches_regex is not configured' );
		};

	subtest name_config => sub {
		my $config_hash = {
			allowed_branches => 'master,main , release'
			};
		my $config = Local::Config->new( $config_hash );
		no strict 'refs';
		local *{'Module::Release::config'} = sub { $config };
		can_ok( $release, 'config' );
		isa_ok( $release->config, 'Local::Config' );

		ok(   defined $release->config->allowed_branches,       'allowed_branches is configured' );
		ok( ! defined $release->config->allowed_branches_regex, 'allowed_branches_regex is not configured' );

		subtest do_not_match => sub {
			foreach my $branch ( qw(Release maint remaster test feature/master main/feature) ) {
				no strict 'refs';
				*{'Module::Release::vcs_branch'} = sub { $branch };
				is( $release->vcs_branch, $branch, "Mock branch <$branch> is correct" );
				ok( ! $release->is_allowed_branch, "Mock branch <$branch> is disallowed" );
				}
			};

		subtest do_not_match => sub {
			foreach my $branch ( qw(main master release) ) {
				no strict 'refs';
				*{'Module::Release::vcs_branch'} = sub { $branch };
				is( $release->vcs_branch, $branch, "Mock branch <$branch> is correct" );
				ok( $release->is_allowed_branch,   "Mock branch <$branch> is allowed" );
				}
			}
		};

	subtest re_config => sub {
		no warnings qw(redefine);
		my $config_hash = {
			allowed_branches_regex => '\b(release|master|test)\b'
			};
		my $config = Local::Config->new( $config_hash );
		no strict 'refs';
		local *{'Module::Release::config'} = sub { $config };
		can_ok( $release, 'config' );
		isa_ok( $release->config, 'Local::Config' );

		ok( ! defined $release->config->allowed_branches,       'allowed_branches is not configured' );
		ok(   defined $release->config->allowed_branches_regex, 'allowed_branches_regex is configured' );

		subtest do_not_match => sub {
			foreach my $branch ( qw(main/feature mock Release mAster tester) ) {
				no strict 'refs';
				*{'Module::Release::vcs_branch'} = sub { $branch };
				is( $release->vcs_branch, $branch, "Mock branch <$branch> is correct" );
				ok( ! $release->is_allowed_branch, "Mock branch <$branch> is allowed" );
				}
			};

		subtest do_not_match => sub {
			foreach my $branch ( qw(release test feature/master) ) {
				no strict 'refs';
				*{'Module::Release::vcs_branch'} = sub { $branch };
				is( $release->vcs_branch, $branch, "Mock branch <$branch> is correct" );
				ok( $release->is_allowed_branch,   "Mock branch <$branch> is allowed" );
				}
			}
		};

	};

done_testing();
