use lib qw( ./blib/lib ../blib/lib );

# Check we can create objects and adding data works
# as well as clearing data.

use Test::More tests => 78;
use HTTP::Date;

BEGIN { use_ok( 'SVG::TT::Graph' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Pie' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Line' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Bar' ); }
BEGIN { use_ok( 'SVG::TT::Graph::BarHorizontal' ); }
BEGIN { use_ok( 'SVG::TT::Graph::BarLine' ); }
BEGIN { use_ok( 'SVG::TT::Graph::TimeSeries' ); }
BEGIN { use_ok( 'SVG::TT::Graph::XY' ); }

# Different data for different graph types
my @titles = ('Sales 2002', 'Sales 2003');
# data for timeseries
my @data_cpu_02 = (['2003-09-03 09:30:00',23],['2003-09-03 09:45:00',54],['2003-09-03 10:00:00',67],['2003-09-03 10:15:00',12]);
my @data_cpu_03 = ('2003-09-04 23:00:21',30,'2005-01-01 00:45:09',10.2);
# data for XY graphs
my @data_disk_02 = ([0.1,23],[0.8,54],[0.55,67],[1.02,12]);
my @data_disk_03 = (3,30, 2.7,10.2);
# data for all other graphs
my @data_fields = ('Jan', 'Feb', 'Mar');
my @data_sales_02 = (12, 45, 21);
my @data_sales_03 = (24, 55, 61);

# Test all graph types
my @types = qw(Line Bar BarHorizontal Pie BarLine TimeSeries XY);
foreach my $type (@types) {

  my @fields;
  my @data1;
  my @data2;
  my $quer1;
  my $quer2;
  my $res1;
  my $res2;
  if ($type eq 'TimeSeries') {
    @fields = undef;
    @data1  = @data_cpu_02;
    $quer1  = $data_cpu_02[0][0];
    $res1   = $data_cpu_02[0][1];
    @data2  = @data_cpu_03;
    $quer2  = $data_cpu_03[2];
    $res2   = $data_cpu_03[3];
  } elsif ($type eq 'XY') {
    @fields = undef;
    @data1  = @data_disk_02;
    $quer1  = $data_disk_02[0][0];
    $res1   = $data_disk_02[0][1];
    @data2  = @data_disk_03;
    $quer2  = $data_disk_03[2];
    $res2   = $data_disk_03[3];
  } else {
    @fields = @data_fields;
    @data1  = @data_sales_02;
    $quer1  = $fields[1];
    $res1   = $data1[1];
    @data2  = @data_sales_03; 
    $quer2  = $fields[2];
    $res2   = $data2[2];
  }

  my $module = "SVG::TT::Graph::$type";
  eval {
    my $gr = $module->new({
    });
  };
  if (scalar @fields > 1) {
    ok($@,'Croak ok as no fields supplied');
  } else {
    ok(!$@, 'Croak not ok as no fields need to be supplied');
  }

  my $graph = $module->new({
    'fields' => \@fields,
  });

  isa_ok($graph,$module);
  
  # Check we croak if no data
  eval {
    $graph->burn();
  };
  ok($@, 'Burn method croaked as expected - no data has been set');
  
  $graph->add_data({
    'data' => \@data1,
    'title' => $titles[0],
  });
  
  is(scalar(@{$graph->{data}}), 1, 'Data set 1 added');

  is($graph->{data}->[0]->{title}, $titles[0], 'Data set 1 - title set ok');

  if ( ($type eq 'TimeSeries') || ($type eq 'XY') ) {
    my $found = 0;
    for my $pair (@{$graph->{data}->[0]->{pairs}}) {
      my ($x, $y) = @$pair;
      my $val = $type eq 'TimeSeries' ? str2time($quer1) : $quer1;
      if ($val == $x) {
        $found = 1;
        last;
      }
    }
    is $found, 1, 'Data set 1 - data set ok';
  } else {
    is($graph->{data}->[0]->{data}->{$quer1}, $res1, 'Data set 1 - data set ok');
  }

  $graph->add_data({
    'data' => \@data2,
    'title' => $titles[1],
  });

  is(scalar(@{$graph->{data}}), 2, 'Data set 2 added');
  is($graph->{data}->[1]->{title}, $titles[1], 'Data set 2 - title set ok');

  if ( ($type eq 'TimeSeries') || ($type eq 'XY') ) {
    my $found = 0;
    for my $pair (@{$graph->{data}->[1]->{pairs}}) {
      my ($x, $y) = @$pair;
      my $val = $type eq 'TimeSeries' ? str2time($quer2) : $quer2;
      if ($val == $x) {
        $found = 1;
        last;
      }
    }
    is $found, 1, 'Data set 2 - data set ok';
  } else {
    is($graph->{data}->[1]->{data}->{$quer2}, $res2, 'Data set 2 - data set ok');
  }

  $graph->clear_data();
  
  is(scalar(@{$graph->{data}}),0,'Data cleared ok');

}
