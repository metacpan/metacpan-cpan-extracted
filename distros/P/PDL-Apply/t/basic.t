use strict;
use warnings;

use PDL;
use Test::More;
use Test::Number::Delta relative => 0.00001;

use PDL::Apply ':all';

my $x = pdl([40.7,81.7,28.9,33.3,40.8,16.3]);
my $y = pdl([
 [
  [87.2, 81.4, 82.5, 67.6, 36.3],
  [77.2, 60.8, 73.5, 50.2, 36.1],
  [28.1, 40.5, 68.4, 84.8, 31.1],
 ],
 [
  [18.5, 87.2, 57.1, 89.5, 46.9],
  [87.7, 52.5, 88.5, 79.9, 51.6],
  [80.8, 17.8, 65.7, 11.8, 37.6],
 ],
]);
my $slices1 = indx([ [0, 2], [4, 5] ]);
my $slices2 = indx([ [0, 2], [1, 4] ]);

delta_ok($x->apply_over('sum'), 241.7);
delta_ok($y->apply_over('sum')->unpdl, [
                                         [  355, 297.8, 252.9],
                                         [299.2, 360.2, 213.7],
                                        ]);

# due to 'BAD' values it is not possible to use delta_ok()
ok(all(abs(apply_rolling($x, 3, 'sum') - pdl('[BAD, BAD, 151.3, 143.9, 103, 90.4]')) < .0000001));
ok(all(abs(apply_rolling($y, 3, 'sum') - pdl('[
                                               [
                                                [ BAD, BAD, 251.1, 231.5, 186.4],
                                                [ BAD, BAD, 211.5, 184.5, 159.8],
                                                [ BAD, BAD,   137, 193.7, 184.3],
                                               ],
                                               [
                                                [ BAD, BAD, 162.8, 233.8, 193.5],
                                                [ BAD, BAD, 228.7, 220.9,   220],
                                                [ BAD, BAD, 164.3,  95.3, 115.1],
                                               ]
                                              ]')) < .0000001));

delta_ok($x->apply_slice($slices1, 'sum')->unpdl, [151.3, 57.1]);
delta_ok($y->apply_slice($slices2, 'sum')->unpdl, [
                                                    [
                                                     [251.1, 267.8],
                                                     [211.5, 220.6],
                                                     [  137, 224.8],
                                                    ],
                                                    [
                                                     [162.8, 280.7],
                                                     [228.7, 272.5],
                                                     [164.3, 132.9],
                                                    ]
                                                   ]);

done_testing();
