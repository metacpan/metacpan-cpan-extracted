package RDF::DOAP::Change::Bugfix;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose::Role;
requires qw( rdf_about rdf_model );

use RDF::DOAP::Issue;
use RDF::DOAP::Types -types;

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');
my $dc   = 'RDF::Trine::Namespace'->new('http://purl.org/dc/terms/');
my $dcs  = 'RDF::Trine::Namespace'->new('http://ontologi.es/doap-changeset#');

has fixes => (
	is         => 'ro',
	isa        => ArrayRef[Issue],
	coerce     => 1,
	lazy       => 1,
	builder    => '_build_fixes',
);

sub _build_fixes
{
	my $self = shift;
	return [] unless $self->has_rdf_about;
	return [] unless $self->has_rdf_model;
	
	my $model = $self->rdf_model;
	[ map 'RDF::DOAP::Issue'->rdf_load($_, $model), $model->objects($self->rdf_about, $dcs->fixes) ];
}

override changelog_links => sub
{
	my $self = shift;
	my @pages = map {
		my $bug = $_;
		grep defined, $bug->page, @{ $bug->see_also || [] };
	} @{ $self->fixes };
	return (@pages, super());
};

my %ABBREV = (
	GITHUB    => 'GH',
	RT        => 'RT',
);
override changelog_lines => sub
{
	my $self = shift;
	my @lines = super();
	my @added = map {
		!defined($_->id)                      ? () :
		($_->rdf_about =~ /\b(RT|GITHUB)\b/i) ? "Fixes $ABBREV{uc($1)}#$_->{id}." :
		"Fixes #$_->{id}."
	} @{ $self->fixes };
	splice(@lines, 1, 0, @added) if @added;
	return @lines;
};

1;
