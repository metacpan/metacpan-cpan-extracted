use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use File::Which qw(which);
use t::Util;

my $bin = scalar which 'nytprofhtml';
plan skip_all => 'nytprofhtml script is not in your PATH.' unless defined $bin;

BEGIN {
    use Plack::Middleware::Profiler::NYTProf;
    $ENV{NYTPROF} = 'start=no:sigexit=int:stmts=0:savesrc=0';
    Plack::Middleware::Profiler::NYTProf->preload;
}

subtest 'preload Devel::NYTProf' => sub {
    my $app = Plack::Middleware::Profiler::NYTProf->wrap( simple_app(),
        enable_reporting => 0, );

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );

        is $res->code, 200, "Response is returned successfully";

        my $regex = qr/nytprof\.\d+\-(\d+)\.\d+\.out/;
        for my $file ( glob("nytprof.*.out") ) {
            like $file, $regex, "Exists profiling result file: $file";
        }
    };

    unlink glob("nytprof*.out");

};

done_testing;
