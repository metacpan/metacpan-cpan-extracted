
use Test::More;
use RRDTool::OO;
use Log::Log4perl qw(:easy);

my $rrd = RRDTool::OO->new( file => "blech.rrd" );

plan tests => 1;

my $start_time     = 1080460200;
my $nof_iterations = 40;
my $end_time       = $start_time + $nof_iterations * 60;

my $rc = $rrd->create(
    start     => $start_time - 10,
    step      => 60,
    data_source => { name      => 'load1',
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
);

my %options = (
      image          => "mygraph.png",
      vertical_label => 'Test vdef, gprint',
      width          => 1000,
      start          => 0,
      end            => 1,
      draw           => {
        type      => 'hidden',
        dsname    => 'tx',
        cfunc     => 'MAX',
        name      => 'tx_max',
      },
      gprint      => {
          'draw'      => 'tx_max',
          'format'    => 'AVERAGE:%5.1lf%s Avg,',
      },
);

eval { 
    $rrd->graphv( %options );
};

  # Don't modify the incoming array (bug reported by Florian Eckert)
ok !exists $options{ draw }->{ file }, 
  "no in-depth modification of input array";

# use Data::Dumper;
# print Dumper( \@options );

END { unlink "blech.rrd"; }
