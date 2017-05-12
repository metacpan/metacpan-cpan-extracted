use strict;
use Plack::Middleware::Profiler::NYTProf;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use t::Util;


subtest 'No load Devel::NYTProf' => sub {
    my $result_dir      = tempdir();
    my $result_filename = $$;

    my $app = Plack::Middleware::Profiler::NYTProf->wrap(
        sub {
            my $env = shift;

            my $find = 0;
            for my $pm (keys %INC) {
                $find = 1 if $pm eq 'Devel/NYTProf.pm';
            }
            return [ '200', [ 'Content-Type' => 'text/plain' ], ["$find"] ];
        },
        enable_profile   => sub { 0 },
        enable_reporting => 0,
    );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );

        is $res->code, 200, "Response is returned successfully";
        is $res->content, '0', 'No load Devel::NYTProf';

        ok !-e "nytprof.out", "Doesn't exist nytprof.out";
        ok !-e path( "report", "index.html" ), "Doesn't exist report file";
    };

    unlink glob("nytprof*.out");
};

done_testing;
