
use Test::More qw(no_plan);
use RRDTool::OO;

$| = 1;

###################################################
my $LOGLEVEL = $OFF;
###################################################

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init({level => $LOGLEVEL, layout => "%L: %m%n", 
                          category => 'rrdtool',
                          file => 'stdout'});

my $rrd = RRDTool::OO->new(file => "foo");

    # create with superfluous param
$rrd->create(
    data_source => { name      => 'foobar',
                     type      => 'GAUGE',
                   },
    archive     => { cfunc   => 'MAX',
                     xff     => '0.5',
                     cpoints => 5,
                     rows    => 10,
                   },
);

ok(-e "foo", "RRD exists");

#####################################################
# Change ds type
#####################################################
my $hashref = $rrd->info();
is($hashref->{'ds'}{'foobar'}{'type'}, 'GAUGE', 'dstype before tune');
$rrd->tune(dsname => 'foobar', type => "COUNTER");

$hashref = $rrd->info();
is($hashref->{'ds'}{'foobar'}{'type'}, 'COUNTER', 'dstype tuned');

#####################################################
# Change ds name
#####################################################
$rrd->tune(name => "newfoobar");

$hashref = $rrd->info();
is($hashref->{'ds'}{'newfoobar'}{'type'}, 'COUNTER', 'dsname tuned');

#####################################################
# Change minimum/maximum
#####################################################
$rrd->tune(maximum => 20, minimum => 5);

$hashref = $rrd->info();
is($hashref->{'ds'}{'newfoobar'}{'max'}, '20', 'maximum tuned');
is($hashref->{'ds'}{'newfoobar'}{'min'}, '5', 'minimum tuned');

#####################################################
# Change heartbeat
#####################################################
is($hashref->{'ds'}{'newfoobar'}{'minimal_heartbeat'}, '600', 'heartbeat before');
$rrd->tune(heartbeat => 200);

$hashref = $rrd->info();
is($hashref->{'ds'}{'newfoobar'}{'minimal_heartbeat'}, '200', 'heartbeat tuned');

#####################################################
# Get last update
#####################################################
my $time = $rrd->last();

like($time, qr/^\d+$/, 'last update timestamp');

#####################################################
# Get first update
#####################################################
my $time = $rrd->first();

like($time, qr/^\d+$/, 'first update timestamp');

END { unlink "foo"; }
