use strict;

use Test::More;
use Plack::Middleware::Profiler::KYTProf;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use t::TestProfile;
use t::TestPerson;

# TODO use logger to test profiling
subtest 'Can profile a test module with the custom profile' => sub {
    my $app = sub {
        my $env      = shift;
        return [ '200', [ 'Content-Type' => 'text/plain' ], ["Hello World"] ];
    };

    $app = Plack::Middleware::Profiler::KYTProf->wrap( $app,
        profiles => ['t::TestProfile'] );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );
        warn "Error Occured. Response body:" . $res->content if $res->code eq 500;

        t::TestPerson->name();

        is $res->code, 200, "Response is returned successfully";
    };
};

done_testing;
