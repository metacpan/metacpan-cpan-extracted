package Test::BDD::Cucumber::Definitions::HTTP;

use strict;
use warnings;

use Const::Fast;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Hash::MultiValue;
use HTTP::Response;
use HTTP::Tiny;
use Test::BDD::Cucumber::Definitions qw(S :validator);
use Test::More;

our $VERSION = '0.41';

our @EXPORT_OK = qw(HTTP);

my $http = HTTP::Tiny->new();

# Exceptions will result in a pseudo-HTTP status code of 599 and a reason of "Internal Exception".
# The content field in the response will contain the text of the exception.
const my $HTTP_INTERNAL_EXCEPTION => 599;

## no critic [Subroutines::RequireArgUnpacking]

sub HTTP {
    return __PACKAGE__;
}

sub request_header_set {
    my $self = shift;
    my ( $header, $value ) = validator_ns->(@_);

    S->{HTTP} = __PACKAGE__;

    S->{_HTTP}->{request}->{headers}->{$header} = $value;

    return;
}

sub request_content_set {
    my $self = shift;
    my ($content) = validator_s->(@_);

    S->{HTTP} = __PACKAGE__;

    S->{_HTTP}->{request}->{content} = $content;

    return;
}

sub request_send {
    my $self = shift;
    my ( $method, $url ) = validator_nn->(@_);

    S->{HTTP} = __PACKAGE__;

    my $options = {
        headers => S->{_HTTP}->{request}->{headers},
        content => $self->_encode_utf8( S->{_HTTP}->{request}->{content} ),
    };

    S->{_HTTP}->{response} = $http->request( $method, $url, $options );

    if ( S->{_HTTP}->{response}->{status} == $HTTP_INTERNAL_EXCEPTION ) {
        fail('Http request was sent');
        diag( S->{_HTTP}->{response}->{content} );
    }

    diag( 'Http request method = ' . np $method);
    diag( 'Http request url = ' . np $url );
    diag( 'Http request headers = ' . np S->{_HTTP}->{request}->{headers} );
    diag( 'Http request content = ' . np S->{_HTTP}->{request}->{content} );

    # Clean http request
    S->{_HTTP}->{request} = undef;

    S->{_HTTP}->{response_object} = HTTP::Response->new(
        S->{_HTTP}->{response}->{status},
        S->{_HTTP}->{response}->{reason},
        [ Hash::MultiValue->from_mixed( S->{_HTTP}->{response}->{headers} )->flatten ],
        S->{_HTTP}->{response}->{content},
    );

    return;
}

sub response_code_eq {
    my $self = shift;
    my ($code) = validator_i->(@_);

    is( S->{_HTTP}->{response}->{status}, $code, qq{Http response code eq "$code"} );

    diag( sprintf 'Http response status = "%s %s"', S->{_HTTP}->{response}->{status},
        S->{_HTTP}->{response}->{reason} );

    return;
}

sub response_header_eq {
    my $self = shift;
    my ( $header, $value ) = validator_ns->(@_);

    is( S->{_HTTP}->{response}->{headers}->{ lc $header }, $value, qq{Http response header "$header" eq "$value"} );

    diag( 'Http response headers = ' . np S->{_HTTP}->{response}->{headers} );

    return;
}

sub response_header_re {
    my $self = shift;
    my ( $header, $value ) = validator_nr->(@_);

    like( S->{_HTTP}->{response}->{headers}->{ lc $header }, $value, qq{Http response header "$header" re "$value"} );

    diag( 'Http response headers = ' . np S->{_HTTP}->{response}->{headers} );

    return;
}

sub response_content_eq {
    my $self = shift;
    my ($content) = validator_s->(@_);

    is( S->{_HTTP}->{response_object}->decoded_content(), $content, qq{Http response content eq "$content"} );

    diag( 'Http response charset = ' . np S->{_HTTP}->{response_object}->headers->content_type_charset );

    return;
}

sub response_content_re {
    my $self = shift;
    my ($content) = validator_r->(@_);

    like( S->{_HTTP}->{response_object}->decoded_content(), $content, qq{Http response content re "$content"} );

    diag( 'Http response charset = ' . np S->{_HTTP}->{response_object}->headers->content_type_charset );

    return;
}

sub content {
    my $self = shift;

    return S->{_HTTP}->{response_object}->decoded_content;
}

sub _encode_utf8 {
    my $self = shift;
    my ($str) = @_;

    if ( utf8::is_utf8 $str ) {
        utf8::encode $str;
    }

    return $str;
}

1;
