package Test::BDD::Cucumber::Definitions::HTTP;

use strict;
use warnings;

use Const::Fast;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Hash::MultiValue;
use HTTP::Response;
use HTTP::Tiny;
use Test::BDD::Cucumber::Definitions qw(S);
use Test::BDD::Cucumber::Definitions::Validator qw(:all);
use Test::More;

our $VERSION = '0.27';

our @EXPORT_OK = qw(
    http_request_header_set
    http_request_content_set
    http_request_send
    http_response_code_eq
    http_response_header_eq http_response_header_re
    http_response_content_eq http_response_content_re
);

our %EXPORT_TAGS = (
    util => [
        qw(
            http_request_header_set
            http_request_content_set
            http_request_send
            http_response_code_eq
            http_response_header_eq http_response_header_re
            http_response_content_eq http_response_content_re
            )
    ]
);

my $http = HTTP::Tiny->new();

# Exceptions will result in a pseudo-HTTP status code of 599 and a reason of "Internal Exception".
# The content field in the response will contain the text of the exception.
const my $HTTP_INTERNAL_EXCEPTION => 599;

## no critic [Subroutines::RequireArgUnpacking]

sub http_request_header_set {
    my ( $header, $value ) = validator_ns->(@_);

    S->{http}->{request}->{headers}->{$header} = $value;

    return;
}

sub http_request_content_set {
    my ($content) = validator_s->(@_);

    S->{http}->{request}->{content} = $content;

    return;
}

sub http_request_send {
    my ( $method, $url ) = validator_nn->(@_);

    my $options = {
        headers => S->{http}->{request}->{headers},
        content => _encode_utf8( S->{http}->{request}->{content} ),
    };

    S->{http}->{response} = $http->request( $method, $url, $options );

    if ( S->{http}->{response}->{status} == $HTTP_INTERNAL_EXCEPTION ) {
        fail('Http request was sent');
        diag( S->{http}->{response}->{content} );
    }

    diag( 'Http request method = ' . np $method);
    diag( 'Http request url = ' . np $url );
    diag( 'Http request headers = ' . np S->{http}->{request}->{headers} );
    diag( 'Http request content = ' . np S->{http}->{request}->{content} );

    # Clean http request
    S->{http}->{request} = undef;

    S->{http}->{response_object} = HTTP::Response->new(
        S->{http}->{response}->{status},
        S->{http}->{response}->{reason},
        [ Hash::MultiValue->from_mixed( S->{http}->{response}->{headers} )->flatten ],
        S->{http}->{response}->{content},
    );

    return;
}

sub http_response_code_eq {
    my ($code) = validator_i->(@_);

    is( S->{http}->{response}->{status}, $code, qq{Http response code eq "$code"} );

    diag( sprintf 'Http response status = "%s %s"', S->{http}->{response}->{status}, S->{http}->{response}->{reason} );

    return;
}

sub http_response_header_eq {
    my ( $header, $value ) = validator_ns->(@_);

    is( S->{http}->{response}->{headers}->{ lc $header }, $value, qq{Http response header "$header" eq "$value"} );

    diag( 'Http response headers = ' . np S->{http}->{response}->{headers} );

    return;
}

sub http_response_header_re {
    my ( $header, $value ) = validator_nr->(@_);

    like( S->{http}->{response}->{headers}->{ lc $header }, $value, qq{Http response header "$header" re "$value"} );

    diag( 'Http response headers = ' . np S->{http}->{response}->{headers} );

    return;
}

sub http_response_content_eq {
    my ($content) = validator_s->(@_);

    is( S->{http}->{response_object}->decoded_content(), $content, qq{Http response content eq "$content"} );

    diag( 'Http response charset = ' . np S->{http}->{response_object}->headers->content_type_charset );

    return;
}

sub http_response_content_re {
    my ($content) = validator_r->(@_);

    like( S->{http}->{response_object}->decoded_content(), $content, qq{Http response content re "$content"} );

    diag( 'Http response charset = ' . np S->{http}->{response_object}->headers->content_type_charset );

    return;
}

sub _encode_utf8 {
    my ($str) = @_;

    if ( utf8::is_utf8 $str ) {
        utf8::encode $str;
    }

    return $str;
}

1;
