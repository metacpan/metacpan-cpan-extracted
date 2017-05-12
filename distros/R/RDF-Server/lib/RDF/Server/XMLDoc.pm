package RDF::Server::XMLDoc;

use Moose;

use MooseX::Types::Moose qw(Str Object);

use XML::LibXML;

has document => (
    is => 'rw',
    isa => 'XML::LibXML::Document',
    required => 1
);

#has xml => (
#    is => 'rw',
#    isa => Str,
#    lazy => 1,
#    default => sub {
#        (shift) -> document -> toStringC14N;
#    }
#);

sub xml {
    my $self = shift;

    return $self -> document -> toStringC14N unless @_;

    my $parser = XML::LibXML -> new();
    $self -> document($parser -> parse_string( shift ));
}

use overload '""' => sub { (shift) -> xml };

around new => sub {
    my($method, $self) = splice @_, 0, 2;

    if( @_ % 2 == 0 ) {
        my %options = @_;

        if( $options{xml} && !$options{document} ) {
            my $parser = XML::LibXML -> new();
            $options{document} = $parser -> parse_string($options{xml});
        }
        $self -> $method( %options );
    }

    my $doc = shift @_;

    if( blessed $doc ) {
        if( $doc -> isa('XML::LibXML::Document') ) {
            return $self -> $method( document => $doc );
        }
        elsif( $doc -> isa('RDF::Server::XMLDoc') ) {
            return $doc;
        }
    }
    else {
        my $parser = XML::LibXML -> new();
        return $self -> $method( document => $parser -> parse_string($doc) );
    }
};

no Moose;

1;

__END__

=pod

=head1 NAME

RDF::Server::XMLDoc - convenience class for managing XML documents

=head1 SYNOPSIS

 my $doc = RDF::Server::XMLDoc -> new( $xml );
 my $parsed_doc = $doc -> document;
 my $stringified_doc = $doc -> xml;

=head1 METHODS

=over 4

=item document

=item xml

=back
