use strict;
use warnings;

use Test::More;

use File::Spec;
use HTTP::Request::Common 6.22;
use HTTP::Status qw/ :constants status_message /;
use Plack::Builder;
use Plack::Response;
use Plack::Test;

use Plack::Middleware::Static;

my $handler = builder {

    enable "EmulateOPTIONS";

    enable "Static",
        path => sub { s!^/share/!! },
        root => "t/share";

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
        req  => HEAD('/share/test.html'),
        code => HTTP_OK,
    },
    {
        line => __LINE__,
        req  => HEAD('/share/test.txt'),
        code => HTTP_NOT_FOUND,
    },
    {
        line => __LINE__,
        req  => OPTIONS('/share/test.html'),
        code => HTTP_OK,
        headers => {
            Allow => 'GET, HEAD, OPTIONS',
        },
    },
    {
        line => __LINE__,
        req  => OPTIONS('/share/test.txt'),
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
