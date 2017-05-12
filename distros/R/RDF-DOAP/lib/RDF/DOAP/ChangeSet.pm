package RDF::DOAP::ChangeSet;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;
extends qw(RDF::DOAP::Resource);

use RDF::DOAP::ChangeSet;
use RDF::DOAP::Change;
use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $doap = 'RDF::Trine::Namespace'->new('http://usefulinc.com/ns/doap#');
my $dc   = 'RDF::Trine::Namespace'->new('http://purl.org/dc/terms/');
my $dcs  = 'RDF::Trine::Namespace'->new('http://ontologi.es/doap-changeset#');

has items => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => ArrayRef[Change],
	coerce     => 1,
	uri        => $dcs->item,
	multi      => 1,
);

1;
