package Plack::Auth::SSO::ResponseParser::CAS;

use strict;
use utf8;
use Data::Util qw(:check);
use Moo;
use XML::LibXML;
use XML::LibXML::XPathContext;

our $VERSION = "0.0132";

with "Plack::Auth::SSO::ResponseParser";

sub parse {

    my ( $self, $obj ) = @_;

    my $xpath;

    if ( is_instance( $obj, "XML::LibXML" ) ) {

        $xpath = XML::LibXML::XPathContext->new( $obj );

    }
    else {

        $xpath = XML::LibXML::XPathContext->new(
            XML::LibXML->load_xml( string => $obj )
        );

    }

    $xpath->registerNs( "cas", "http://www.yale.edu/tp/cas" );
    $self->from_doc( $xpath );

}

sub from_doc {

    my ( $self, $xpath ) = @_;

    my %attributes;

    for my $attr ( $xpath->find( "/cas:serviceResponse/cas:authenticationSuccess/cas:attributes/child::*" )->get_nodelist() ) {

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
        uid => $xpath->findvalue( "/cas:serviceResponse/cas:authenticationSuccess/cas:user" )
    };

}

1;
