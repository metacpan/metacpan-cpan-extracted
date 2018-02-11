package Test::BDD::Cucumber::Definitions::HTTP;

use strict;
use warnings;

use Carp;
use Const::Fast;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use Hash::MultiValue;
use HTTP::Response;
use HTTP::Tiny;
use Params::ValidationCompiler qw( validation_for );
use Test::BDD::Cucumber::Definitions::TypeConstraints qw(:all);
use Test::BDD::Cucumber::StepFile qw();
use Test::More;
use Try::Tiny;

our $VERSION = '0.11';

our @EXPORT_OK = qw(
    S C
    request_send
    code_eq
    header_set header_eq header_re
    content_set content_eq content_re content_eq_decoded content_re_decoded
);
our %EXPORT_TAGS = (
    util => [
        qw(
            request_send
            code_eq
            header_set header_eq header_re
            content_set content_eq content_re content_eq_decoded content_re_decoded
            )
    ]
);

my $http = HTTP::Tiny->new();

# Exceptions will result in a pseudo-HTTP status code of 599 and a reason of "Internal Exception".
# The content field in the response will contain the text of the exception.
const my $HTTP_INTERNAL_EXCEPTION => 599;

## no critic [Subroutines::RequireArgUnpacking]

sub S { return Test::BDD::Cucumber::StepFile::S }
sub C { return Test::BDD::Cucumber::StepFile::C }

my $validator_header_set = validation_for(
    params => [

        # http request header name
        { type => ValueString },

        # http request header value
        { type => ValueString },
    ]
);

sub header_set {
    my ( $header, $value ) = $validator_header_set->(@_);

    S->{http}->{request}->{headers}->{$header} = $value;

    return;
}

my $validator_content_set = validation_for(
    params => [

        # http request content
        { type => ValueString },
    ]
);

sub content_set {
    my ($content) = $validator_content_set->(@_);

    S->{http}->{request}->{content} = $content;

    return;
}

my $validator_request_send = validation_for(
    params => [

        # http request method
        { type => ValueString },

        # http request url
        { type => ValueString },
    ]
);

sub request_send {
    my ( $method, $url ) = $validator_request_send->(@_);

    if ( $ENV{BDD_HTTP_HOST} ) {
        $url =~ s/\$BDD_HTTP_HOST/$ENV{BDD_HTTP_HOST}/x;
    }

    my $options = {
        headers => S->{http}->{request}->{headers},
        content => S->{http}->{request}->{content},
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

my $validator_code_eq = validation_for(
    params => [

        # http response code
        { type => ValueInteger },
    ]
);

sub code_eq {
    my ($code) = $validator_code_eq->(@_);

    is( S->{http}->{response}->{status}, $code, qq{Http response code eq "$code"} );

    diag( sprintf 'Http response status = "%s %s"', S->{http}->{response}->{status}, S->{http}->{response}->{reason} );

    return;
}

my $validator_header_eq = validation_for(
    params => [

        # http response header name
        { type => ValueString },

        # http response header value
        { type => ValueString },

    ]
);

sub header_eq {
    my ( $header, $value ) = $validator_header_eq->(@_);

    is( S->{http}->{response}->{headers}->{ lc $header }, $value, qq{Http response header "$header" eq "$value"} );

    diag( 'Http response headers = ' . np S->{http}->{response}->{headers} );

    return;
}

my $validator_header_re = validation_for(
    params => [

        # http response header name
        { type => ValueString },

        # http response header value
        { type => ValueRegexp }
    ]
);

sub header_re {

    my ( $header, $value ) = $validator_header_re->(@_);

    like( S->{http}->{response}->{headers}->{ lc $header }, $value, qq{Http response header "$header" re "$value"} );

    diag( 'Http response headers = ' . np S->{http}->{response}->{headers} );

    return;
}

my $validator_content_eq = validation_for(
    params => [

        # http response content
        { type => ValueString },

    ]
);

sub content_eq {
    my ($content) = $validator_content_eq->(@_);

    is( S->{http}->{response}->{content}, $content, qq{Http response content eq "$content"} );

    return;
}

sub content_eq_decoded {
    my ($content) = $validator_content_eq->(@_);

    is( S->{http}->{response_object}->decoded_content(), $content, qq{Http response decoded content eq "$content"} );

    diag( 'Http response content type = ' . np S->{http}->{response_object}->headers->content_type );
    diag( 'Http response content charset = ' . np S->{http}->{response_object}->headers->content_type_charset );

    return;
}

my $validator_content_re = validation_for(
    params => [

        # http response content
        { type => ValueRegexp }
    ]
);

sub content_re {
    my ($content) = $validator_content_re->(@_);

    like( S->{http}->{response}->{content}, $content, qq{Http response content re "$content"} );

    return;
}

sub content_re_decoded {
    my ($content) = $validator_content_re->(@_);

    like( S->{http}->{response_object}->decoded_content(), $content, qq{Http response decoded content re "$content"} );

    diag( 'Http response content type = ' . np S->{http}->{response_object}->headers->content_type );
    diag( 'Http response content charset = ' . np S->{http}->{response_object}->headers->content_type_charset );

    return;
}

1;
