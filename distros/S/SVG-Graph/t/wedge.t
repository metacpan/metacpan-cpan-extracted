use strict;

BEGIN {
  eval { require Test; };
  if($@){
    use lib 't';
  }
  use Test;
  plan test => 9;
}

use SVG::Graph;
ok(1);
use SVG::Graph::Data::Datum;
ok(2);

my $graph = SVG::Graph->new(width=>600,height=>600,margin=>30);
ok(3);

my $group = $graph->add_frame();
ok(4);

my $xval = 1;
my $yval = 1;
my $zval = 1;

my @d = ();
for(1..20){
	push @d, SVG::Graph::Data::Datum->new(x=>$xval,y=>$yval,z=>$zval);
    $xval = $xval % 2;
    $yval = $yval % 3;
    $zval = $zval % 4;	
}
ok(5);

my $data = SVG::Graph::Data->new(data => \@d);
ok(6);

$group->add_data($data);
ok(7);

$group->add_glyph('wedge');
ok(8);

$graph->draw();
ok(9);
