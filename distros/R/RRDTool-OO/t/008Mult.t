# Test multiple data sources and multiple archives in one RRD.

use Test::More qw(no_plan);
use RRDTool::OO;
use FindBin qw( $Bin );

require "$Bin/inc/round.t";

use Log::Log4perl qw(:easy);

#Log::Log4perl->easy_init({level => $INFO, layout => "%L: %m%n", 
#                          category => 'rrdtool',
#                          file => 'stdout'});

my $rrd = RRDTool::OO->new( file => 'foo' );

END { unlink('foo'); }

my $start_time     = 1080460200;
my $nof_iterations = 40;
my $end_time       = $start_time + $nof_iterations * 60;

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
    data_source => { name      => 'load2',
                     type      => 'GAUGE',
                     heartbeat => 90,
                     min       => 0,
                     max       => 100.0,
                   },
    archive     => { cfunc    => 'MAX',
                     xff      => '0.5',
                     cpoints  => 1,
                     rows     => 5,
                   },
    archive     => { cfunc    => 'MAX',
                     xff      => '0.5',
                     cpoints  => 5,
                     rows     => 10,
                   },
);

is($rc, 1, "create ok");
ok(-f "foo", "RRD exists");

for(0..$nof_iterations) {
    my $time = $start_time + $_ * 60;
    my $value = sprintf "%.2f", 2 + $_ * 0.1;

    $rrd->update(time => $time, values => [$value, $value + 10]);
}

    # short-term archive
my @expected_val1 = qw(1080462360:5.6 1080462420:5.7 1080462480:5.8
                       1080462540:5.9 1080462600:6);
my @expected_val2 = qw(1080462360:15.6 1080462420:15.7 1080462480:15.8
                       1080462540:15.9 1080462600:16);

$rrd->fetch_start(start => $end_time - 5*60, end => $end_time,
                  cfunc => 'MAX');
$rrd->fetch_skip_undef();
my $count = 0;
while(my($time, $val1, $val2) = $rrd->fetch_next()) {
    last unless defined $val1;
    $val1 = roundfloat( $val1 );
    is("$time:$val1", shift @expected_val1, "match expected value");
    is("$time:$val2", shift @expected_val2, "match expected value");
    $count++;
}
is($count, 5, "items found");

exit 0;
