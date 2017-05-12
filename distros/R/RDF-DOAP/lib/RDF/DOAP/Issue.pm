package RDF::DOAP::Issue;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.012';

use Moose;
extends qw(RDF::DOAP::Resource);

use RDF::DOAP::Types -types;
use RDF::DOAP::Utils -traits;

use RDF::Trine::Namespace qw(rdf rdfs owl xsd);
my $dbug  = 'RDF::Trine::Namespace'->new('http://ontologi.es/doap-bugs#');

has reporter => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[ Person ],
	coerce     => 1,
	uri        => $dbug->reporter,
	multi      => 1,
	gather_as  => ['thanks'],
);

has assignee => (
	traits     => [ WithURI, Gathering ],
	is         => 'ro',
	isa        => ArrayRef[ Person ],
	coerce     => 1,
	uri        => $dbug->assignee,
	multi      => 1,
	gather_as  => ['contributor'],
);

has id => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => String,
	coerce     => 1,
	uri        => $dbug->id,
);

has $_ => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => Identifier,
	coerce     => 1,
	uri        => $dbug->$_,
) for qw( severity status );

has page => (
	traits     => [ WithURI ],
	is         => 'ro',
	isa        => Identifier,
	coerce     => 1,
	uri        => $dbug->page,
);

1;
