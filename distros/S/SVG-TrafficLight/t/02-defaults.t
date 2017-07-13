use Test::More;
use Test::Deep;

use SVG::TrafficLight;

ok(my $tl = SVG::TrafficLight->new, 'Got an object');
isa_ok($tl, 'SVG::TrafficLight', 'Got the right kind of object');

my $colours =  {
   red   => ['rgb(63,0,0)',  'red'],
   amber => ['rgb(59,29,0)', 'orange'],
   green => ['rgb(0,63,0)',  'green'],
};

my $seq = [
  { red => 0, amber => 0, green => 1 },
  { red => 0, amber => 1, green => 0 },
  { red => 1, amber => 0, green => 0 },
  { red => 1, amber => 1, green => 0 },
  { red => 0, amber => 0, green => 1 },
];

is($tl->radius, 50, 'Correct radius');
is($tl->diameter, 100, 'Correct diameter');
is($tl->padding, 25, 'Correct padding');
is($tl->light_width, 150, 'Correct light width');
is($tl->light_height, 400, 'Correct light height');
is($tl->width, 900, 'Correct document width');
is($tl->height, 450, 'Correct document height');
is($tl->corner_radius, 20, 'Correct corner radius');
isa_ok($tl->svg, 'SVG');
cmp_deeply($tl->colours, $colours, 'Correct colours');
cmp_deeply($tl->sequence, $seq, 'Correct sequence');

done_testing;
