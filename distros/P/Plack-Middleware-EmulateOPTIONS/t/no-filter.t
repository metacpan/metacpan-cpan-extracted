use v5.14;
use warnings;

use Test::More;

use HTTP::Request::Common 6.21;
use HTTP::Status qw/ :constants status_message /;
use Plack::Builder;
use Plack::Response;
use Plack::Test;

my $handler = builder {

    enable "EmulateOPTIONS";

    sub {
        my ($env) = @_;

        my $code = HTTP_OK;
        $code = HTTP_METHOD_NOT_ALLOWED unless $env->{REQUEST_METHOD} =~ /^(?:GET|HEAD)$/;
        $code = HTTP_NOT_FOUND          unless $env->{PATH_INFO} eq "/";

        my $res = Plack::Response->new( $code, [ 'Content-Type' => 'text/plain' ], [ status_message($code) ] );

        return $res->finalize;
    }
};

my @Tests = (
    {
        line => __LINE__,
        req  => HEAD('/'),
        code => HTTP_OK,
    },
    {
        line => __LINE__,
        req  => GET('/'),
        code => HTTP_OK,
    },
    {
        line => __LINE__,
        req  => POST('/'),
        code => HTTP_METHOD_NOT_ALLOWED,
    },
    {
        line => __LINE__,
        req  => GET('/not-found.html'),
        code => HTTP_NOT_FOUND,
    },
    {
        line => __LINE__,
        req  => OPTIONS('/'),
        code => HTTP_OK,
        headers => {
            Allow => 'GET, HEAD, OPTIONS',
        },
    },
    {
        line => __LINE__,
        req  => OPTIONS('/not-found.html'),
        code => HTTP_NOT_FOUND,
    },
);

test_psgi
  app    => $handler,
  client => sub {
    my $cb = shift;

    for my $case (@Tests) {

        $case->{method} //= $case->{req}->method;
        $case->{path}   //= $case->{req}->uri->path_query;

        my $desc = join( " ", $case->{method}, $case->{path} );
        subtest $desc => sub {
            my $res = $cb->( $case->{req} );
            is $res->code, $case->{code}, $desc;

            if (my $headers = $case->{headers}) {
                for my $field (keys %$headers ) {
                    is $res->header($field), $headers->{$field}, "$field header";
                }
            }

        };

    }

  };

done_testing;
