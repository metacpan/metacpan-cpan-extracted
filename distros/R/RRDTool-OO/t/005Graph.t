
use Test::More tests => 20;
use RRDTool::OO;
use Log::Log4perl qw(:easy);

$SIG{__WARN__} = sub {
    use Carp qw(cluck);
    print cluck();
};

##############################################
# Configuration
##############################################
my $VIEW = 0;     # Display graphs
my $VIEWPROG = "xv"; # using viewprog
my $LOGLEVEL = $INFO;  # Level of detail
##############################################

sub view {
    return unless $VIEW;
    system($VIEWPROG, $_[0]) if ( -x $VIEWPROG );
}

#Log::Log4perl->easy_init({level => $LOGLEVEL, layout => "%m%n", 
##                          category => 'rrdtool',
#file => 'stderr',
#layout => '%F{1}-%L: %m%n',
#});

my $rrd = RRDTool::OO->new(file => "foo");

######################################################################
# Create a RRD "foo"
######################################################################

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
    data_source => { name      => 'load2',
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
    archive     => { cfunc    => 'MIN',
                     xff      => '0.5',
                     cpoints  => 1,
                     rows     => 5,
                   },
    archive     => { cfunc    => 'MIN',
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

    $rrd->update(time => $time, values => { 
        load1 => $value,
        load2 => $value+1,
    });
}

$rrd->fetch_start(start => $start_time, end => $end_time,
                  cfunc => 'MAX');
$rrd->fetch_skip_undef();
while(my($time, $val1, $val2) = $rrd->fetch_next()) {
    last unless defined $val1;
    DEBUG "$time:$val1:$val2";
}

######################################################################
# Create anoter RRD "bar"
######################################################################

my $rrd2 = RRDTool::OO->new(file => "bar");

$start_time     = 1080460200;
$nof_iterations = 40;
$end_time       = $start_time + $nof_iterations * 60;

$rc = $rrd2->create(
    start     => $start_time - 10,
    step      => 60,
    data_source => { name      => 'load3',
                     type      => 'GAUGE',
                     heartbeat => 90,
                     min       => 0,
                     max       => 10.0,
                   },
    archive     => { cfunc    => 'AVERAGE',
                     xff      => '0.5',
                     cpoints  => 5,
                     rows     => 10,
                   },
);

is($rc, 1, "create ok");
ok(-f "bar", "RRD exists");

for(0..$nof_iterations) {
    my $time = $start_time + $_ * 60;
    my $value = sprintf "%.2f", 10 - $_ * 0.1;

    $rrd2->update(time => $time, values => { 
        load3 => $value,
    });
}

$rrd2->fetch_start(start => $start_time, end => $end_time,
                   cfunc => 'AVERAGE');
$rrd2->fetch_skip_undef();
while(my($time, $val1) = $rrd2->fetch_next()) {
    last unless defined $val1;
    DEBUG "$time:$val1";
}

######################################################################
# Draw simple graph
######################################################################
        # Simple line graph
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'My Salary',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Draw simple area graph
######################################################################
        # Simple line graph
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'My Salary',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => { 
          type  => "area",
          color => "00FF00",
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Draw simple stacked graph
######################################################################
        # Simple stacked graph
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'My Salary',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => { 
          type  => "area",
          color => "00FF00",
      },
      draw           => { 
          dsname => "load2",
          type   => "stack",
          color  => "0000FF",
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Draw a graph from two RRD files
######################################################################
$rrd->graph(
  image          => "mygraph.png",
  vertical_label => 'My Salary',
  start          => $start_time,
  end            => $start_time + $nof_iterations * 60,
  width          => 700,
  height         => 300,
  draw           => {
          type      => "line",
          thickness => 3,
          color     => '0000ff',
          dsname    => 'load1',
          cfunc     => 'MIN',
  },
  draw           => {
          file      => 'bar',
          type      => "line",
          thickness => 3,
          color     => 'ff0000',
          # dsname    => 'load3',
          # cfunc     => 'AVERAGE',
  },
);

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Two draws in one graph, one DEF, one CDEF
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'draws and gprints',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => { 
          type      => "line",
          thickness => 3,
          color     => "00FF00",
          name      => "first",
          legend    => 'firstg',
      },
      gprint         => {
        draw      => 'first',
        cfunc     => 'AVERAGE',
        format    => 'Average1=%lf',
      },
      draw          => { 
          type      => "line",
          thickness => 3,
          color     => "0000FF",
          cdef      => "first,2,*",
          name      => "second",
          legend    => 'secondg',
      },
      gprint         => {
        draw      => 'second',
        cfunc     => 'AVERAGE',
        format    => 'Average2=%lf',
      },
      draw          => { 
          type      => "line",
          thickness => 3,
          color     => "0000FF",
          cdef      => "first,3,*",
          name      => "third",
          legend    => 'thirdg',
      },
      gprint         => {
        draw      => 'third',
        cfunc     => 'AVERAGE',
        format    => 'Average3=%lf',
      },
      draw          => { 
          type      => "line",
          thickness => 3,
          color     => "0000FF",
          cdef      => "first,4,*",
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'My Salary',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'line',
        color     => 'FF0000', # red line
        name      => 'firstgraph',
        legend    => 'Unmodified Load',
      },
      draw        => {
        type      => 'line',
        color     => '00FF00', # green line
        cdef      => "firstgraph,2,*",
        legend    => 'Load Doubled Up',
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'My Salary',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'hidden',
        color     => 'FF0000', # red line
        name      => 'firstgraph',
        legend    => 'Unmodified Load',
      },
      draw        => {
        type      => 'line',
        color     => '00FF00', # green line
        cdef      => "firstgraph,2,*",
        legend    => 'Load Doubled Up',
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test gprint
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Test gprint',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'line',
        color     => 'FF0000', # red line
        name      => 'firstgraph',
        legend    => 'Unmodified Load',
      },
      draw           => {
        type      => 'hidden',
        name      => 'average_of_first_draw',
        vdef      => 'firstgraph,AVERAGE',
      },
      gprint         => {
        draw   => 'average_of_first_draw', 
        format => "Hello %lf",
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test comment, vrule
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Test comment, vrule',
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'line',
        color     => 'FF0000', # red line
        name      => 'firstgraph',
        legend    => 'Unmodified Load',
      },
      gprint         => {
        draw      => 'firstgraph',
        cfunc     => 'AVERAGE',
        format    => 'Average=%lf',
      },
      comment     => "Remember, 83% of all statistics are made up",
      vrule       => {
                time   => $start_time + 10 * 60,
                legend => "vrule1",
                color  => "#ff0000",
      },
      vrule       => {
                time   => $start_time + 20 * 60,
                legend => "vrule2",
                color  => "#00ff00",
      },
      hrule       => {
                value   => 2.5,
                legend => "hrule1",
                color  => "#0000ff",
      },
      hrule       => {
                value   => 3.5,
                legend => "hrule2",
                color  => "#aa00aa",
      },
#      font => { name    => "/usr/X11R6/lib/X11/fonts/TTF/VeraBd.ttf",
#                size    => 32,
#                element => "title",
#              },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test line, area
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Test line, area',
      width          => 1000,
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'line',
        color     => 'FF0000', # red line
        name      => 'firstgraph',
        legend    => 'Unmodified Load',
      },
      line        => {
                value  => 3,
                legend => "line1",
                color  => "#00ff00",
                stack  => 1,
      },
      line        => {
                value  => 10,
                legend => "line2",
                color  => "#ff0000",
      },
      area        => {
                value  => 5,
                legend => "area1",
                color  => "#0000ff",
      },
      tick        => {
                legend => "ticks",
                color  => "#00ff00",
                fraction => 0.5,
      },
      shift       => {
                draw  => 'firstgraph',
                offset => 1000,
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test stack compatibility
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Stack',
      width          => 1000,
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'stack',
        color     => 'FF0000', # red area
        name      => 'firstgraph',
        legend    => 'first',
      },
      draw           => {
        type      => 'stack',
        color     => '00FF00', # green area
        name      => 'secondgraph',
        legend    => 'second',
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

######################################################################
# Test stacks
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Stack',
      width          => 1000,
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'area',
        color     => 'FF0000', # red area
        name      => 'firstgraph',
        legend    => 'first',
        stack     => 1,
      },
      draw           => {
        type      => 'line',
        color     => '00FF00', # green line
        name      => 'secondgraph',
        legend    => 'second',
        stack     => 1,
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

VDEF:
######################################################################
# Test vdef, gprint
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Test vdef, gprint',
      width          => 1000,
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'line',
        name      => 'firstdraw',
        legend    => 'Unmodified Load',
      },
      draw           => {
        type      => 'hidden',
        name      => 'average_of_firstgraph',
        vdef      => 'firstdraw,AVERAGE',
      },
      gprint         => {
        draw      => 'average_of_firstgraph',
        format    => 'Average=%lf',
      },
    );

view("mygraph.png");
ok(-f "mygraph.png", "Image exists");
unlink "mygraph.png";

PRINT:
######################################################################
# Test print
######################################################################
    $rrd->graph(
      image          => "mygraph.png",
      vertical_label => 'Test vdef, gprint',
      width          => 1000,
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
        type      => 'line',
        name      => 'firstdraw',
        legend    => 'Unmodified Load',
      },
      draw           => {
        type      => 'hidden',
        name      => 'average_of_firstgraph',
        vdef      => 'firstdraw,AVERAGE',
      },
      print         => {
        draw      => 'average_of_firstgraph',
        format    => "\"Average=%lf\"",
      },
    );

		my @prgraph = (
      image          => "mygraph.png",
      start          => $start_time,
      end            => $start_time + $nof_iterations * 60,
      draw           => {
          type      => "hidden",
          name      => "firstdraw",
          #cfunc     => 'AVERAGE'
      },
      draw           => {
          type      => "hidden",
          color     => '00FF00', # green line
          name      => "in95precent",
          vdef      => "firstdraw,95,PERCENT"
      },

      print         => {
          draw      => 'in95precent',
          format    => "Result = %3.2lf",
        },
		);
    $rrd->graph(
			@prgraph,
    );


SKIP: {
    skip "Skipping potentially buggy RRDs < 1.4 for print/format", 1 if 
        $RRDs::VERSION < 1.4;
    is($rrd->print_results()->[0], "Result = 6.00", "print result");
}

######################################################################
# Draw simple graphv
######################################################################
SKIP: {
    eval "use RRDs 1.3";
    skip "RRDs is too old: need 1.3 for graphv", 2 if $@;

        # Simple line graph
    $rrd->graphv( @prgraph );

    ok(-f "mygraph.png", "Image exists");
    unlink "mygraph.png";
    skip "Skipping potentially buggy RRDs < 1.4 for print/format", 1 if 
       $RRDs::VERSION < 1.4;
    is($rrd->print_results()->{'print[0]'}, "Result = 6.00", "print result");
}

unlink("foo");
unlink("bar");
