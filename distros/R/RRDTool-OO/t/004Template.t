
###########################################
# Test meta data discovery
# Mike Schilli, 2004 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Test::More qw(no_plan);
use RRDTool::OO;

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({
#    category => 'rrdtool',
#    level    => $INFO, 
#    layout   => "%m%n", 
#    file     => 'stdout'
#});

my $rrd = RRDTool::OO->new(file => "rrdtooltest.rrd");

my $start_time     = 1080460200;

my $rc = $rrd->create(
    start     => $start_time - 10,
    step      => 1,
    data_source => { name      => 'ds1',
                     type      => 'GAUGE',
                   },
    data_source => { name      => 'ds2',
                     type      => 'GAUGE',
                   },
    data_source => { name      => 'ds3',
                     type      => 'GAUGE',
                   },
    archive     => { cfunc    => 'MAX',
                     cpoints  => 1,
                     rows     => 10,
                   },
);

for(0..10) {
    my $time = $start_time + $_;
    $rrd->update(
        time   => $time,
        values => {  "ds1" => 1,
                     "ds2" => 2,
                     "ds3" => 3,
                  },
    );
}

$rrd->fetch_start(start => $start_time, end => $start_time + 10);
$rrd->fetch_skip_undef();
my $count = 0;
while(my($time, @val) = $rrd->fetch_next()) {
    last unless defined $val[0];
    like "$time:@val", qr/\d+:1 2 3/, "values in correct order";
    $count++;
}
is($count, 10, "10 items found");

END { unlink "rrdtooltest.rrd"; }
