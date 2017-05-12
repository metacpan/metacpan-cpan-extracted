package RDF::Server::Semantic::RDF::Types;

use MooseX::Types -declare => [qw(
    RDFHandler
    RDFCodeRef
)];

use RDF::Server::Types qw( Handler Model );

use MooseX::Types::Moose qw(
    ArrayRef
    HashRef
    CodeRef
    Object
);

subtype RDFHandler,
    as Handler;

coerce RDFHandler,
    from ArrayRef =>
    via {
        RDF::Server::Semantic::RDF -> build_rdfic_handler(@_);
    };

coerce RDFHandler,
    from HashRef =>
    via {
        RDF::Server::Semantic::RDF -> build_rdfic_handler(@_);
    };

subtype RDFCodeRef,
    as CodeRef;

coerce RDFCodeRef,
    from ArrayRef,
    via {
        my($a) = @_;
        return sub { $a };
    };

coerce RDFCodeRef,
    from Object,
    via {
        my($a) = @_;
        return sub { [ $a ] };
    };

1;

__END__
