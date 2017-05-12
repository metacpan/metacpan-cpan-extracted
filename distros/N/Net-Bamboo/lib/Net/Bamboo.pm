package Net::Bamboo;
{
  $Net::Bamboo::VERSION = '0.01';
}

# ABSTRACT: OO Interface for the REST services provided by Atlassian Bamboo

use Moose;
use MooseX::Types::URI qw(Uri FileUri DataUri);

use LWP::UserAgent;
use XML::XPath;
use XML::Tidy;

use Net::Bamboo::Project;
use Net::Bamboo::Plan;
use Net::Bamboo::Build;

has hostname	=> (isa => 'Str',	is => 'rw');
has username	=> (isa => 'Str',	is => 'rw');
has password	=> (isa => 'Str',	is => 'rw');
has realm		=> (isa => 'Str',	is => 'rw', default => 'protected-area');
has debug		=> (isa => 'Bool',	is => 'ro', default => 0);

has _ua =>
	isa			=> 'LWP::UserAgent',
	is			=> 'ro',
	lazy_build	=> 1;

has _uri =>
	isa			=> Uri,
	is			=> 'rw',
	lazy_build	=> 1,
	coerce		=> 1;

has _projects =>
	traits		=> [ 'Hash' ],
	isa			=> 'HashRef[Net::Bamboo::Project]',
	is			=> 'ro',
	lazy_build	=> 1,
	handles		=>
	{
		projects		=> 'values',
		num_projects	=> 'count',
		project_keys	=> 'keys',
		project			=> 'get'
	};

sub _build__ua
{
	my $self = shift;

	my $netloc	= $self->_uri->host . ':' . $self->_uri->port;
	my $ua		= new LWP::UserAgent;

	$ua->credentials($netloc, $self->realm, $self->username, $self->password);
	$ua->add_handler(request_send => sub { warn $_[0]->as_string if $self->debug; () });

	return $ua;
}

sub _build__uri
{
	my $self = shift;

	my $uri = new URI;

	$uri->scheme('http');
	$uri->host($self->hostname);
	$uri->path('/rest/api/latest/');
	$uri->query_form({ os_authType => 'basic' });

	return $uri;
}

sub request
{
	my $self	= shift;
	my $path	= shift;
	my $params	= shift || {};

	die 'second argument to request must be a reference to a hash'
		if ref($params) ne 'HASH';

	my $uri = $self->_uri->new_abs($path, $self->_uri);

	$uri->query_form($self->_uri->query_form, %$params);

	my $res = $self->_ua->get($uri);

	warn XML::Tidy->new(xml => $res->content)->tidy->toString if $self->debug;

	return new XML::XPath xml => $res->content;
}

sub _build__projects
{
	my $self = shift;

	my $xp = $self->request(project => { expand => 'projects.project.plans.plan' });
	my $ns = $xp->find('/projects/projects/project');

	my $projects = {};

	foreach my $node ($ns->get_nodelist) {
		my $project = new Net::Bamboo::Project
			bamboo	=> $self,
			key		=> $node->getAttribute('key'),
			name	=> $node->getAttribute('name'),
			link	=> $node->findvalue('link/@href')->value;

		my $ns = $node->find('plans/plan');

		foreach my $node ($ns->get_nodelist) {
			my $plan = new Net::Bamboo::Plan
				project		=> $project,
				key			=> $node->getAttribute('shortKey'),
				name		=> $node->getAttribute('shortName'),
				link		=> $node->findvalue('link/@href')->value,
				num_stages	=> $node->findvalue('stages/@size')->value,
				is_enabled	=> $node->getAttribute('enabled') eq 'true' ? 1 : 0,
				is_building	=> $node->findvalue('isBuilding')->value eq 'true' ? 1 : 0,
				is_active	=> $node->findvalue('isActive')->value eq 'true' ? 1 : 0;

			$project->add_plan($plan->key => $plan);
		}

		$projects->{$project->key} = $project;
	}

	return $projects;
}

sub refresh
{
	my $self = shift;

	$self->clear__projects && $self->_projects;
}

1;

__END__

=head1 SYNOPSIS

 use Net::Bamboo;

 # basics

 my $bamboo = new Net::Bamboo;

 $bamboo->hostname('bamboo.domain.com'); # hostname of bamboo server
 $bamboo->username('myuser');            # bamboo username
 $bamboo->password('mypass');            # bamboo password
 $bamboo->debug($bool);                  # debug mode (dump HTTP/XML)

 # projects

 $bamboo->projects;      # array of Net::Bamboo::Project
 $bamboo->num_projects;  # number of projects
 $bamboo->project_keys;  # list of project keys
 $bamboo->project($key); # get project by bamboo key

 my $project = $bamboo->project($key);

 $project->key;  # project key
 $project->name; # project name

 # plans

 $project->plans;        # list of Net::Bamboo::Plan objects
 $project->num_plans;    # number of plans
 $project->plan_keys;    # list of plan keys
 $project->plan($key);   # get plan by bamboo key

 my $plan = $bamboo->plan($key);

 $plan->key;             # plan key
 $plan->name;            # plan name
 $plan->num_stages;      # number of stages in plan
 $plan->is_enabled;      # flag: is plan enabled
 $plan->is_building;     # flag: is plan currently building
 $plan->is_active;       # flag: is plan active
 $plan->fqkey;           # fully qualified key (project key + plan key)

 # builds

 $plan->builds;          # list of Net::Bamboo::Build objects (five most recent)
 $plan->build_numbers;   # list of build numbers
 $plan->build($num);     # get build by number
 $plan->latest_build;    # get most recent build

 my $build = $plan->build($num);

 $build->number;         # build number
 $build->reason;         # build reason
 $build->date_started;   # build start date/time (DateTime object)
 $build->date_completed; # build end date/time (DateTime object)
 $build->duration;       # build duration (DateTime::Duration object)
 $build->succeeded;      # flag: build success?
 $build->failed;         # flag: build failure?
 $build->num_tests_ok;   # number of successful unit tests
 $build->num_tests_fail; # number of failed unit tests

=head1 DESCRIPTION

Net::Bamboo is a simple OO interface to the RESTy interface exposed by
Atlassian's Bamboo tool for continuous integration.  The implementation
is functionally lazy for the most part.  Projects and plans are pulled
in a single bulk request while the builds are pulled per plan as they
are needed.  Builds cycle often, so there exists a Plan->refresh method
you may use to clear the attribute storing the builds; this will cause
Net::Bamboo::Plan to pull a new build the next time it's requested.  A
similar method is available for the Net::Bamboo object as well, though
it's likely to be used much less often.

This is a rough first cut.  Pull requests against my github repository
are more than welcome.

=head1 AUTHOR

Mike Eldridge <diz@cpan.org>

=cut

