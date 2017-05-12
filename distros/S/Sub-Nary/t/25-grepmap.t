#!perl -T

use strict;
use warnings;

use Test::More tests => 32;

use Sub::Nary;

my $sn = Sub::Nary->new();

my ($x, $y, @a, %h);

sub zeroorone {
 return (rand() < 0.1) ? () : 1;
}

sub oneortwo {
 if (rand() < 0.1) {
  return 3
 } else {
  4, 5
 }
}

sub onetwothree {
 my $r = rand();
 if ($r < 0.1) {
  return 3
 } elsif ($r < 0.9) {
  return 4, 5
 }
 return 4, do { 5, 6 };
}

my $exp_2 = { 1 => 0.5, 2 => 0.5 };

# { 1 => 0.5, 2 => 0.5 } * 0.5 + { 2 => 0.25, 3 => 0.5, 4 => 0.25 } * 0.5
my $exp_22 = { 1 => 0.5 * 0.5, 2 => (0.5 + 0.25) * 0.5, 3 => 0.5 * 0.5, 4 => 0.25 * 0.5 };

# { 1 => 0.5, 2 => 0.25, 3 => 0.25 } * 0.5 + { 2 => 0.25, 3 => 0.25, 4 => 0.3125, 5 => 0.125, 6 => 0.0625 } * 0.5
my $exp_32 = { 1 => 0.5/2, 2 => (0.25+0.25)/2, 3 => (0.25+0.25)/2, 4 => (0.3125)/2, 5 => (0.125)/2, 6 => (0.0625)/2 };

my $b3 = 0.5 ** 3;
my $exp_23 = { 3 => $b3, 4 => 3 * $b3, 5 => 3 * $b3, 6 => $b3 };

my @tests = (
 [ sub { grep { return 2, 4 } 5 .. 10 },                  2 ],
 [ sub { grep { $_ > 1 } do { return 2, 4; 5 .. 10 } },   2 ],
 [ sub { grep { return 2, 4 } () },                       0 ],
 [ sub { grep { return $_ ? 2 : (3, 4) } 7 .. 8 },        $exp_2 ],
 [ sub { grep { return 2 if $_; 3 } 7 .. 8 },
                                                  { 1 => 0.75, list => 0.25 } ],
 [ sub { grep { $_ > 1 } do { return $x ? 7 : (8, 9) } }, $exp_2 ],
 [ sub { grep { return $_ ? 2 : (3, 4) } do { return 3 .. 5 if $x; } },
                                           { 3 => 0.5, 1 => 0.25, 2 => 0.25 } ],
 [ sub { grep { return $_ ? 2 : (3, 4) } do { return 3 .. 5 if $x; () } },
                                                       { 3 => 0.5, 0 => 0.5 } ],

 [ sub { map { return 2, 4 } 5 .. 10 },                  2 ],
 [ sub { map { $_ + 1 } do { return 2, 4; 5 .. 10 } },   2 ],
 [ sub { map { return 2, 4 } () },                       0 ],
 [ sub { map { return $_ ? 2 : (3, 4) } 7 .. 8 },        $exp_2 ],
 [ sub { map { return 2 if $_; 3 } 7 .. 8 },
                                                     { 1 => 0.75, 2 => 0.25 } ],
 [ sub { map { $_ > 1 } do { return $x ? 7 : (8, 9) } }, $exp_2 ],
 [ sub { map { return $_ ? 2 : (3, 4) } do { return 3 .. 5 if $x; } },
                                           { 3 => 0.5, 1 => 0.25, 2 => 0.25 } ],
 [ sub { map { return $_ ? 2 : (3, 4) } do { return 3 .. 5 if $x; () } },
                                                       { 3 => 0.5, 0 => 0.5 } ],

 [ sub { grep { 1 } 1 .. 10 },      'list' ],
 [ sub { grep { 1 } @_ },           'list' ],
 [ sub { grep { 1 } () },           0 ],

 [ sub { map { $_ } 1 .. 3 },                       3 ],
 [ sub { map { () } @_ },                           0 ],
 [ sub { map { @_ } () },                           0 ],
 [ sub { map { @_ } 1, 2 },                         'list' ],
 [ sub { map { $_ } oneortwo() },                   { 1 => 0.5, 2 => 0.5 } ],
 [ sub { map { $_ ? 7 : (8, 9) } 1 .. 3 },          $exp_23 ],
 [ sub { map oneortwo, 1 .. 3 },                    $exp_23 ],
 [ sub { map oneortwo, @_ },                        'list' ],
 [ sub { map zeroorone, @_ },                       { 0 => 0.5, list => 0.5 } ],
 [ sub { map { $_ ? () : 12 } do { $x ? 7 : () } }, { 0 => 0.75, 1 => 0.25 } ],
 [ sub { map zeroorone, do { $x ? 7 : () } },       { 0 => 0.75, 1 => 0.25 } ],
 [ sub { map oneortwo, oneortwo },                  $exp_22 ],
 [ sub { map onetwothree, oneortwo },               $exp_32 ],
);

my $i = 1;
for (@tests) {
 my $r = $sn->nary($_->[0]);
 my $exp = ref $_->[1] ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'grep/map test ' . $i);
 ++$i;
}
