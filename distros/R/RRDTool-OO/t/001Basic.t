
use Test::More qw(no_plan);
use RRDTool::OO;
use POSIX qw(setlocale LC_ALL);
use FindBin qw( $Bin );

require "$Bin/inc/round.t";

use Log::Log4perl qw(:easy);
#Log::Log4perl->easy_init({level => $INFO, layout => "%L: %m%n", 
#                          category => 'rrdtool',
#                          file => 'stdout'});

my $rrd;
my $loc = setlocale( LC_ALL, "C" );

######################################################################
    # constructor missing mandatory parameter
eval { $rrd = RRDTool::OO->new(); };
like($@, qr/Mandatory parameter 'file' not set/, "new without file");

    # constructor featuring illegal parameter
eval { $rrd = RRDTool::OO->new( file => 'file', foobar => 'abc' ); };
like($@, qr/Illegal parameter 'foobar' in new/, "new with illegal parameter");

    # Legal constructor
$rrd = RRDTool::OO->new( file => 'foo' );

######################################################################
# create missing everything
######################################################################
eval { $rrd->create(); };
like($@, qr/Mandatory parameter/, "create missing everything");

    # create missing data_source
eval { $rrd->create( archive => {} ); };
like($@, qr/Mandatory parameter/, "create missing data_source");

    # create missing archive
eval { $rrd->create( data_source => {} ); };
like($@, qr/No archives/, "create missing archive");

    # create with superfluous param
eval { $rrd->create(
    data_source => { name      => 'foobar',
                     type      => 'foo',
                     # heartbeat => 10,
                   },
    archive     => { cfunc   => 'abc',
                     name    => 'archname',
                     xff     => '0.5',
                     cpoints => 5,
                     rows    => 10,
                   },
) };

like($@, qr/Illegal parameter 'name'/, "create missing heartbeat");

######################################################################
# Run the test example in
# http://www.linux-magazin.de/Artikel/ausgabe/2004/06/perl/perl.html
######################################################################

my $start_time     = 1080460200;
my $nof_iterations = 40;
my $end_time       = $start_time + $nof_iterations * 60;

my $rc = $rrd->create(
    start     => $start_time - 10,
    step      => 60,
    data_source => { name      => 'load',
                     type      => 'GAUGE',
                     heartbeat => 90,
                     min       => 0,
                     max       => 10.0,
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

    $rrd->update(time => $time, value => $value);
}

    # short-term archive
my @expected = qw(1080462360:5.6 1080462420:5.7 1080462480:5.8
                  1080462540:5.9 1080462600:6);

$rrd->fetch_start(start => $end_time - 5*60, end => $end_time,
                  cfunc => 'MAX');
$rrd->fetch_skip_undef();
my $count = 0;
while(my($time, $val) = $rrd->fetch_next()) {
    last unless defined $val;
      # rrdtool has some inaccurracies [rt.cpan.org #97322]
    $val = roundfloat( $val );
    is("$time:$val", shift @expected, "match expected value");
    $count++;
}
is($count, 5, "items found");

    # long-term archive
@expected = qw(1080461100:3.5 1080461400:4 1080461700:4.5 1080462000:5 1080462300:5.5 1080462600:6);

$rrd->fetch_start(start => $end_time - 30*60, end => $end_time,
                  cfunc => 'MAX');
$rrd->fetch_skip_undef();
$count = 0;
while(my($time, $val) = $rrd->fetch_next()) {
    last unless defined $val;
        # older rrdtool installations show an additional value
    next if "$time:$val" eq "1080460800:3";
    is("$time:$val", shift @expected, "match expected value");
    $count++;
}
is($count, 6, "items found");

######################################################################
# check info for this rrd
######################################################################
my $info = $rrd->info;
is $info->{'ds'}{'load'}{'type'} => 'GAUGE', 'check RRDTool::OO::info';
is $info->{'ds'}{'load'}{'max'} => '10', 'check RRDTool::OO::info';
is $info->{'rra'}['1']{'cf'} => 'MAX', 'check RRDTool::OO::info';

######################################################################
# Failed update: time went backwards
######################################################################
$rrd->{raise_error} = 0;
ok(! $rrd->update(value => 123, time => 123), 
   "update with expired timestamp");
$rrd->{raise_error} = 1;

like($rrd->error_message(), qr/illegal attempt to update using time \d+ when last update time is \d+ \(minimum one second step\)/, "check error message");

######################################################################
# Ok update
######################################################################
ok($rrd->update(value => 123, time => 1080500000), 
   "update with ok timestamp");

######################################################################
# Check what happens if the rrd is write-protected all of a sudden
######################################################################
SKIP: {
    chmod 0444, "foo";
    skip "can't make test file unwritable (are you root?)", 1 if -w "foo";

    eval {
        $rrd->update(value => 123, time => 1080500100);
    };

    if($@) {
        ok($@, "update on write-protected rrd");
    } else {
        fail("update on write-protected rrd");
    }
}

######################################################################
    # constructor including raise_error (cpan #7897)
$rrd = RRDTool::OO->new(file => "foo1", raise_error => 0);
eval { $rrd->update(value => 123, time => 123); };
is($@, "", "Error caught");

$rrd = RRDTool::OO->new(file => "foo1", raise_error => 1);
eval { $rrd->update(value => 123, time => 123); };
like($@, qr/No such file or directory/, "Error raised");

END { unlink('foo'); }
