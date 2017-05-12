package RDF::DOAP::Repository;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;
extends qw(RDF::DOAP::Resource);

use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => Identifier,
	coerce     => 1,
	uri        => do { (my $x = $_) =~ s/_/-/g; $doap->$x },
) for qw( browse location );

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => String,
	coerce     => 1,
	uri        => do { (my $x = $_) =~ s/_/-/g; $doap->$x },
) for qw( anon_root module );

1;
