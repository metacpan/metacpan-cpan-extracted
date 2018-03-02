package Plack::Auth::SSO::ResponseParser::CAS;

use Catmandu::Sane;
use Catmandu::Util qw(:check :is);
use Moo;
use XML::LibXML;
use XML::LibXML::XPathContext;
use namespace::clean;

our $VERSION = "0.011";

with "Plack::Auth::SSO::ResponseParser";

has xpath => (
    is => "ro",
    lazy => 1,
    builder => "_build_xpath",
    init_arg => undef
);

sub _build_xpath {
    my $xpath = XML::LibXML::XPathContext->new();
    $xpath->registerNs( "cas", "http://www.yale.edu/tp/cas" );
    $xpath;
}

sub parse {

    my ( $self, $obj ) = @_;

    $self->from_doc(
        is_instance( $obj, "XML::LibXML" ) ? $obj : XML::LibXML->load_xml( string => $obj )
    );

}

sub from_doc {

    my ( $self, $libxml ) = @_;

    my $xpath = $self->xpath();

    my %attributes;

    for my $attr ( $libxml->find( "/cas:serviceResponse/cas:authenticationSuccess/cas:attributes/child::*", $xpath )->get_nodelist() ) {

        my $key     = $attr->localname();
        my $value   = $attr->textContent();

        if ( exists( $attributes{$key} ) ) {

            if ( is_string( $attributes{$key} ) ) {

                $attributes{$key} = [ $attributes{$key}, $value ];

            }
            elsif ( is_array_ref( $attributes{$key} ) ) {

                $attributes{$key} = [ @{ $attributes{$key} }, $value ];

            }

        }
        else {

            $attributes{$key} = $value;

        }

    }

    +{
        extra => {},
        info => \%attributes,
        uid => $libxml->findvalue( "/cas:serviceResponse/cas:authenticationSuccess/cas:user", $xpath )
    };

}

1;
