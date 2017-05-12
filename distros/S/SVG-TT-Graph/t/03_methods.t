use lib qw( ./blib/lib ../blib/lib );

# Test using the methods to set the config

use Test::More tests => 98;

BEGIN { use_ok( 'SVG::TT::Graph' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Pie' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Line' ); }
BEGIN { use_ok( 'SVG::TT::Graph::Bar' ); }
BEGIN { use_ok( 'SVG::TT::Graph::BarHorizontal' ); }
BEGIN { use_ok( 'SVG::TT::Graph::BarLine' ); }
BEGIN { use_ok( 'SVG::TT::Graph::TimeSeries' ); }
BEGIN { use_ok( 'SVG::TT::Graph::XY' ); }

my @fields = qw(Jan Feb Mar);

my @types = qw(Line Bar BarHorizontal Pie BarLine TimeSeries XY);
foreach my $type (@types) {

  my $module = "SVG::TT::Graph::$type";
  my $graph = $module->new({
    'fields' => \@fields,
  });

  if ($module eq 'SVG::TT::Graph::Pie') {
    eval {
      $graph->show_y_labels();
    };
    ok($@, 'Got error for method show_y_labels not applicable to piecharts');
  } else {
    is($graph->show_y_labels(),1,'default show_y_labels match');
    is($graph->show_y_labels('0'),0,'setting show_y_labels match');
    is($graph->show_y_labels(),0,'new show_y_labels match');
  }

  if ($module eq 'SVG::TT::Graph::BarHorizontal' 
      || $module eq 'SVG::TT::Graph::Bar'
      || $module eq 'SVG::TT::Graph::BarLine'
      || $module eq 'SVG::TT::Graph::Pie') {
    ok(defined $graph->show_title_fields, 'default show_title_fields');
    ok(defined $graph->show_path_title, 'default show_path_title');
  }

  eval {
    $graph->silly_method_that_dont_exist();
  };
  ok($@, 'Got error for method that is not in config');

  # First get_template is easy
  ok(defined $graph->get_template, 'get_template');
  # Second get_template could be empty if the DATA filehandle was not reset
  ok(defined $graph->get_template, 'get_template again');

  ok(defined $graph->compress(),'default compress');
  is($graph->compress(0),0,'setting compress');
  is($graph->compress(1),1);

  ok(defined $graph->tidy(),'default tidy');
  is($graph->tidy(0),0,'setting tidy');
  is($graph->tidy(1),1);

}
