use strict;
use Plack::Middleware::Profiler::NYTProf;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use File::Which qw(which);
use t::Util;

my $bin = scalar which 'nytprofhtml';
plan skip_all => 'nytprofhtml script is not in your PATH.' unless defined $bin;

# FIXME Need to check profile format version 
# The report isn't generated if profile format version isn't matched. 
# 
#subtest 'Change report_dir location' => sub {
#    my $result_dir = tempdir();
#    my $report_dir = tempdir();
#
#    my $app = Plack::Middleware::Profiler::NYTProf->wrap(
#        simple_app(),
#        env_nytprof => "start=no:addpid=0:file="
#            . path( $result_dir, "nytprof.out" ),
#        enable_reporting => 1,
#        report_dir       => sub {$report_dir},
#    );
#
#    ok !-e path( $report_dir, "index.html" ),
#        "Doesn't exists report directory before profiling";
#
#    test_psgi $app, sub {
#        my $cb  = shift;
#        my $res = $cb->( GET "/" );
#
#        is $res->code, 200, "Response is returned successfully";
#
#        ok -e path( $result_dir, "nytprof.out" ), "Exists nytprof.out";
#        ok -e path( $report_dir, "index.html" ),  "Exists the report file";
#        isnt -d "report", 1, "Doesn't exist default report directory";
#    };
#
#    unlink glob("nytprof*.out");
#};

subtest 'Change profiling_result_dir location and output filename' => sub {
    my $result_dir      = tempdir();
    my $result_filename = $$;

    my $app = Plack::Middleware::Profiler::NYTProf->wrap(
        simple_app(),
        env_nytprof => "start=no:addpid=0:file="
            . path( $result_dir, "nytprof.out" ),
        profiling_result_dir       => sub {$result_dir},
        profiling_result_file_name => sub {"nytprof.$result_filename.out"},
        enable_reporting           => 0
    );

    isnt -e path( $result_dir, "nytprof.$result_filename.out" ), 1,
        "Doesn't exists profile before profiling";

    test_psgi $app, sub {
        my $cb  = shift;
        my $res = $cb->( GET "/" );

        is $res->code, 200, "Response is returned successfully";

        ok -e path( $result_dir, "nytprof.$result_filename.out" ),
            "Exists profiling result file";
        ok !-e "nytprof.out", "Doesn't exist nytprof.out";

        ok !-e path( "report", "index.html" ), "Doesn't exist report file";
    };

    unlink glob("nytprof*.out");
};

done_testing;
