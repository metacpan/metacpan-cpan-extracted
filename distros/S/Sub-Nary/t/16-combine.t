#!perl -T

use strict;
use warnings;

use Test::More tests => 24;

use Sub::Nary;

*combine = *Sub::Nary::combine{CODE};

my $h12 = { 1 => 0.5, 2 => 0.5 };

my @tests = (
 [ [ ],       undef ],
 [ [ undef ], undef ],

 [ [ 0 ],                0 ],
 [ [ 1, undef ],         1 ],
 [ [ undef, 2 ],         2 ],
 [ [ 0, 1 ],             1 ],
 [ [ 1, 2 ],             3 ],
 [ [ 2, undef, 3 ],      5 ],

 [ [ 'list' ],       'list' ],
 [ [ 0, 'list' ],        'list' ],
 [ [ 1, 'list' ],        'list' ],
 [ [ 1, undef, 'list' ], 'list' ],
 [ [ 1, 'list', 2 ],     'list' ],

 [ [ $h12 ],             $h12 ],
 [ [ 1, $h12 ],          { 2 => 0.5, 3 => 0.5 } ],
 [ [ $h12, 2 ],          { 3 => 0.5, 4 => 0.5 } ],
 [ [ $h12, undef, 3 ],   { 4 => 0.5, 5 => 0.5 } ],
 [ [ $h12, 'list' ],     'list' ],
 [ [ $h12, 3, 'list' ],  'list' ],
 [ [ 1, 0, $h12, 2, 0 ], { 4 => 0.5, 5 => 0.5 } ],

 [ [ $h12, $h12 ],       { 2 => 0.25, 3 => 0.5, 4 => 0.25 } ],
 [ [ 1, $h12, $h12 ],    { 3 => 0.25, 4 => 0.5, 5 => 0.25 } ],
 [ [ $h12, 2, $h12 ],    { 4 => 0.25, 5 => 0.5, 6 => 0.25 } ],
 [ [ $h12, $h12, 3 ],    { 5 => 0.25, 6 => 0.5, 7 => 0.25 } ],
);

my $i = 1;
for (@tests) {
 my $r = combine(@{$_->[0]});
 my $exp = (not defined $_->[1] or ref $_->[1]) ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'combine test ' . $i);
 ++$i;
}
