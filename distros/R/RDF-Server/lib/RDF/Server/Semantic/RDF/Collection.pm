package RDF::Server::Semantic::RDF::Collection;

use Moose;
with 'RDF::Server::Role::Handler';

use RDF::Server::Types qw( Model );
use RDF::Server::Semantic::RDF::Types qw( RDFCodeRef );

has '+handlers' => (
    isa => RDFCodeRef,
    coerce => 1
);

1;

__END__
