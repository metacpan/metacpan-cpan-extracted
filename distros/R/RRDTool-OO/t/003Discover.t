
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
#    level => $DEBUG, 
#    layout => "%L: %m%n", 
#    file => 'stdout'
#});

my $rrd = RRDTool::OO->new(file => "rrdtooltest.rrd");

        # Create a round-robin database
$rrd->create(
     step        => 1,  # one-second intervals
     data_source => { name      => "mydatasource",
                      type      => "GAUGE" },
     data_source => { name      => "myotherdatasource",
                      type      => "GAUGE" },
     archive     => { rows      => 5,
                      cfunc     => 'MAX',
                      cpoints   => 10,
                    },
     archive     => { rows      => 5,
                      cfunc     => 'MIN',
                      cpoints   => 10,
                    },
);

    # start from scratch with a new object
    # to the same rrd file
$rrd = RRDTool::OO->new(file => "rrdtooltest.rrd");

$rrd->meta_data_discover();
my $dsnames = $rrd->meta_data("dsnames");
my $cfuncs  = $rrd->meta_data("cfuncs");
like("@$cfuncs", qr/MAX/, "check cfunc");
like("@$cfuncs", qr/MIN/, "check cfunc");
like("@$dsnames", qr/mydatasource/, "check dsname");
like("@$dsnames", qr/myotherdatasource/, "check dsname");

END { unlink "rrdtooltest.rrd"; }
