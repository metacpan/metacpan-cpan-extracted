package Test::BDD::Cucumber::Definitions::HTTP::Util;

use strict;
use warnings;

use Carp;
use DDP ( show_unicode => 1 );
use Exporter qw(import);
use HTTP::Tiny;
use Moose::Util::TypeConstraints;
use Params::ValidationCompiler qw( validation_for );
use Test::BDD::Cucumber::StepFile qw();
use Test::More;
use Try::Tiny;

our $VERSION = '0.05';

our @EXPORT_OK = qw(S C request_send code_eq header_re header_set content_re content_set);
our %EXPORT_TAGS = ( util => [qw(request_send code_eq header_re header_set content_re content_set)] );

## no critic [Subroutines::RequireArgUnpacking]

my $http = HTTP::Tiny->new();

sub S { return Test::BDD::Cucumber::StepFile::S }
sub C { return Test::BDD::Cucumber::StepFile::C }

my $validator_header_set = validation_for(
    params => [

        # http request header name
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid http request header name}}
            ),
        },

        # http request header value
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid http request header value}}
            ),
        }
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
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid http request content}}
            ),
        }
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
        { type => enum( [qw(GET HEAD POST PUT DELETE CONNECT OPTIONS TRACE PATCH)] ) },

        # http request url
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid http request url}}
            ),
        }
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

    # Exceptions will result in a pseudo-HTTP status code of 599 and a reason of "Internal Exception".
    # The content field in the response will contain the text of the exception.
    if ( S->{http}->{response}->{status} == 599 ) {
        fail(qq{Http request was sent});
        diag( S->{http}->{response}->{content} );
    }

    diag( 'Http request method = ' . np $method);
    diag( 'Http request url = ' . np $url );
    diag( 'Http request headers = ' . np S->{http}->{request}->{headers} );
    diag( 'Http request content = ' . np S->{http}->{request}->{content} );

    # Clean http request
    S->{http}->{request} = undef;

    return;
}

my $validator_code_eq = validation_for(
    params => [

        # http response code
        {   type => subtype(
                as 'Int',
                message {qq{"$_" is not a valid http response code}}
            ),
        }
    ]
);

sub code_eq {
    my ($code) = $validator_code_eq->(@_);

    is( S->{http}->{response}->{status}, $code, qq{Http response code eq "$code"} );

    diag(
        sprintf( 'Http response status = "%s %s"', S->{http}->{response}->{status}, S->{http}->{response}->{reason} ) );

    return;
}

my $validator_header_re = validation_for(
    params => [

        # http response header name
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid http response header name}}
            ),
        },

        # http response header value
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid regular expression}}
            ),
        }

    ]
);

sub header_re {
    my ( $header, $value ) = $validator_header_re->(@_);

    like(
        S->{http}->{response}->{headers}->{ lc $header },
        qr/$value/,    ## no critic [RegularExpressions::RequireExtendedFormatting]
        qq{Http response header "$header" re "$value"}
    );

    diag( 'Http response headers = ' . np S->{http}->{response}->{headers} );

    return;
}

my $validator_content_re = validation_for(
    params => [

        # http response content
        {   type => subtype(
                as 'Str',
                message {qq{"$_" is not a valid regular expression}}
            ),
        }
    ]
);

sub content_re {
    my ($content) = $validator_content_re->(@_);

    like(
        S->{http}->{response}->{content},
        qr/$content/,    ## no critic [RegularExpressions::RequireExtendedFormatting]
        qq{Http response content re "$content"}
    );

    return;
}

1;
