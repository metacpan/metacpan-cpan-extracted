package RDF::DOAP::Change;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;
extends qw(RDF::DOAP::Resource);

use RDF::DOAP::Person;
use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;
use List::MoreUtils qw(uniq);
use Text::Wrap qw(wrap);

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');
my $dc   = 'RDF::Trine::Namespace'->new('http://purl.org/dc/terms/');
my $dcs  = 'RDF::Trine::Namespace'->new('http://ontologi.es/doap-changeset#');

has blame => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[Person],
	coerce     => 1,
	uri        => $dcs->blame,
	multi      => 1,
	gather_as  => ['contributor'],
);

has thanks => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[Person],
	coerce     => 1,
	uri        => $dcs->thanks,
	multi      => 1,
	gather_as  => ['thanks'],
);

our %ROLES = (
	$dcs->Addition           => 'RDF::DOAP::Change::Addition',
	$dcs->Removal            => 'RDF::DOAP::Change::Removal',
	$dcs->Bugfix             => 'RDF::DOAP::Change::Bugfix',
	$dcs->Update             => 'RDF::DOAP::Change::Update',
	$dcs->Regression         => 'RDF::DOAP::Change::Regression',
	$dcs->Documentation      => 'RDF::DOAP::Change::Documentation',
	$dcs->Packaging          => 'RDF::DOAP::Change::Packaging',
	$dcs->SecurityFix        => 'RDF::DOAP::Change::SecurityFix',
	$dcs->SecurityRegression => 'RDF::DOAP::Change::SecurityRegression',
);

sub BUILD
{
	my $self = shift;
	
	my @roles = grep defined, map $ROLES{$_}, @{ $self->rdf_type || [] };
	push @roles, $ROLES{$dcs->Bugfix}
		if $self->has_rdf_about
		&& $self->has_rdf_model
		&& $self->rdf_model->count_statements($self->rdf_about, $dcs->fixes, undef);
	
	$self->Moose::Util::apply_all_roles(uniq @roles) if @roles;
}

sub changelog_entry
{
	my $self = shift;
	my $text = join "\n", $self->changelog_lines;
	wrap(" - ", "   ", $text);
}

sub changelog_lines
{
	my $self = shift;
	my ($notype) = @_;
	
	my @lines;
	if ($notype)
	{
		@lines = $self->label;
	}
	else
	{
		my @type = sort map $_->uri =~ m{(\w+)$}, @{ $self->rdf_type };
		@lines = "(@type) " . $self->label;
	}
	
	for my $person (uniq sort @{$self->blame||[]}, @{$self->thanks||[]})
	{
		push @lines, sprintf("%s++", $person->to_string('compact'));
	}
	
	push @lines, $self->changelog_links;
	
	return @lines;
}

sub changelog_links
{
	my $self = shift;
	return @{ $self->see_also || [] };
}

1;
