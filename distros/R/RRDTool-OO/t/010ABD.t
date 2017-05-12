# Test dry run mode in RRDTool::OO

use Test::More;
use RRDTool::OO;

use Log::Log4perl qw(:easy);

plan tests => 1;

#Log::Log4perl->easy_init({level => $INFO, layout => "%L: %m%n", 
#                          category => 'rrdtool',
#                          file => 'stdout'});
#

my $rrd = RRDTool::OO->new(
  file        => 'foo',
  raise_error => 1,
);

END { unlink "foo"; }

my $start_time     = 1080460200;
my $nof_iterations = 100;
my $end_time       = $start_time + $nof_iterations * 60;

my $rows = 300;

   # Define the RRD
my $rc = $rrd->create(
    start       => $start_time - 10,
    step        => 60,
    data_source => { name      => 'load1',
                     type      => 'GAUGE',
                     heartbeat => 90,
                     min       => 0,
                     max       => 100.0,
                   },
    archive => { rows  => $rows,
                 cfunc => "MAX",
               },

    hwpredict   => { rows            => $rows,
                     alpha           => 0.50,
                     beta            => 0.50,
                     gamma           => 0.01,
                     seasonal_period => 30,
                     threshold       => 2,
                     window_length   => 9,
                   },
);

my $time  = $start_time;
my $value = 2;

for(0..$nof_iterations) {
    $time  += 60;
    $value += 0.1;
    $value = sprintf "%.2f", $value;
    $rrd->update(time => $time, value => $value);
}

for(1..10) {
    $time += 60;
    $rrd->update(time => $time, value => 0);
}

for(0..$nof_iterations) {
    $time  += 60;
    $value += 0.1;
    $value = sprintf "%.2f", $value;

    $rrd->update(time => $time, value => $value);
}

# $rrd->graph(
#     image => "mygraph.png",
#     start => $start_time,
#     end   => $time,
#     draw           => {
#         type   => "line",
#         color  => 'FF0000',
#         cfunc  => 'MAX',
#         legend => 'max',
#     },
#     draw           => {
#         type   => "line",
#         color  => '0000FF',
#         cfunc  => 'HWPREDICT',
#         legend => 'hwpredict',
#     },
#     draw           => {
#         type   => "line",
#         color  => '00FF00',
#         cfunc  => 'SEASONAL',
#         legend => 'seasonal',
#     },
#     draw           => {
#         type   => "area",
#         color  => '00eeee',
#         cfunc  => 'FAILURES',
#         legend => 'error',
#     },
# );
#
#system("xv mygraph.png");

isnt(count_failures($rrd, $start_time), 0, "aberrant behaviour detected");

###########################################
sub count_failures {
###########################################
    my($rrd, $start_time) = @_;

    $rrd->fetch_start(start => $start_time, end => $end_time + 3600,
                      cfunc => "FAILURES");
    $rrd->fetch_skip_undef();
    my $count = 0;
    while(my($time, $val) = $rrd->fetch_next()) {
        last unless defined $val;
        $count++ if $val;
    }

    return $count;
}
