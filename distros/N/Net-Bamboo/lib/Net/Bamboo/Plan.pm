package # hide from PAUSE
	Net::Bamboo::Plan;

use Moose;

use MooseX::Types::URI qw(Uri FileUri DataUri);

has project		=> (isa => 'Net::Bamboo::Project',	is => 'ro');
has key			=> (isa => 'Str',					is => 'ro');
has name		=> (isa => 'Str',					is => 'ro');
has link		=> (isa => Uri,						is => 'ro', coerce => 1);
has num_stages	=> (isa => 'Int',					is => 'ro');
has is_enabled	=> (isa => 'Bool',					is => 'ro');
has is_building	=> (isa => 'Bool',					is => 'ro');
has is_active	=> (isa => 'Bool',					is => 'ro');

has _builds =>
	traits		=> [ 'Hash' ],
	isa			=> 'HashRef[Net::Bamboo::Build]',
	is			=> 'ro',
	lazy_build	=> 1,
	handles	=>
	{
		build_numbers	=> 'keys',
		builds			=> 'values',
		build			=> 'get'
	};

# get a result baseline

sub _build__builds
{
	my $self = shift;

	my $xp = $self->project->bamboo->request('result/' . $self->fqkey => { expand => 'results[0:5].result' });
	my $ns = $xp->find('/results/results/result');

	my $builds = {};

	foreach my $node ($ns->get_nodelist) {
		my $build = new Net::Bamboo::Build
			plan			=> $self,
			key				=> $node->getAttribute('key'),
			number			=> $node->getAttribute('number'),
			state			=> $node->getAttribute('state'),
			reason			=> $node->findvalue('buildReason')->value,
			date_started	=> $node->findvalue('buildStartedTime')->value,
			date_completed	=> $node->findvalue('buildStartedTime')->value,
			duration		=> $node->findvalue('buildDuration')->value,
			num_tests_ok	=> $node->findvalue('successfulTestCount')->value,
			num_tests_fail	=> $node->findvalue('failedTestCount')->value;

		$builds->{$build->number} = $build;
	}

	return $builds;
}

sub fqkey
{
	my $self = shift;

	return $self->project->key . '-' . $self->key;
}

sub latest_build
{
	my $self = shift;

	my $num = (reverse sort $self->build_numbers)[0];

	$self->build($num);
}

sub refresh
{
	my $self = shift;

	$self->clear__builds && $self->_builds;
}

1;

