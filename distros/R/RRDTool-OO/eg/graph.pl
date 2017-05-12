#!/usr/local/bin/perl
############################################################
# Create a sample graph
# Mike Schilli <mschilli1@aol.com>, 2004
############################################################

use strict;
use warnings;

use RRDTool::OO;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

my $DB  = "example.rrd";
my $IMG = "example.png";

my $rrd = RRDTool::OO->new(file => $DB);

    # Use a reproducable point in time
my $start_time     = 1080460200;
my $nof_iterations = 40;
my $end_time       = $start_time + $nof_iterations * 60;

   # Define the RRD
my $rc = $rrd->create(
    start       => $start_time - 10,
    step        => 60,
    data_source => { name      => 'load1',
                     type      => 'GAUGE',
                   },
    data_source => { name      => 'load2',
                     type      => 'GAUGE',
                   },
    archive     => { rows     => 50,
                   },
);

   # Pump in values
for(0..$nof_iterations) {
    my $time = $start_time + $_ * 60;
    my $value = 2 + $_ * 0.1;

    $rrd->update(
        time   => $time, 
        values => { 
            load1 => $value,
            load2 => $value+1,
        }
    );
}

   # Draw a graph of two different data sources,
   # stacked on top of each other
$rrd->graph(
    image          => $IMG,
    vertical_label => 'A Nice Area Graph',
    start          => $start_time,
    end            => $start_time + $nof_iterations * 60,
    width          => 700,
    height         => 300,
    color          => { back   => '#eeeeee',
                        arrow  => '#ff0000',
                        canvas => '#eebbbb',
                      },
        # First graph
    draw           => {
        name      => 'some_stupid_draw',
        type      => "area",
        color     => '0000ff',
        legend    => 'first legend',
        dsname    => 'load1',
    },
        # Second graph
    draw           => {
        type      => "stack",
        color     => '00ff00',
        dsname    => 'load2',
        legend    => 'second legend',
    },

#    gprint        => {
#        draw      => 'some_stupid_draw',
#        format    => 'avg=%lf',
#        #cfunc     => 'MIN',
#    },
);

print "$IMG ready.\n";
