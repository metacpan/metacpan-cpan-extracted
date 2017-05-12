#!perl -T

use strict;
use warnings;

use Test::More tests => 67;

use Sub::Nary;

my $sn = Sub::Nary->new();

my ($x, $y, @a, %h);

my @tests = (
 [ sub { return },               0 ],
 [ sub { return () },            0 ],
 [ sub { return return },        0 ],
 [ sub { return do { return } }, 0 ],

 [ sub { return 1 },                           1 ],
 [ sub { return 1, 2 },                        2 ],
 [ sub { my $x = 1; $x = 2; return 3, 4, 5; }, 3 ],
 [ sub { do { 1; return 2, 3 } },              2 ],
 [ sub { do { 1; return 2, 3; 4 } },           2 ],
 [ sub { do { 1; return 2, return 3 } },       1 ],
 [ sub { do { return if $x; 2, 3 }, 4 },       { 0 => 0.5, 3 => 0.5 } ],
 [ sub { do { do { return if $x }, 3 }, 4 },   { 0 => 0.5, 3 => 0.5 } ],
 [ sub { do { return if $x; 2, 3 }, do { return 1 if $y; 4, 5, 6 } },
                                           { 0 => 0.5, 1 => 0.25, 5 => 0.25 } ],

 [ sub { return $x },     1 ],
 [ sub { return $x, $y }, 2 ],

 [ sub { return @a },                'list' ],
 [ sub { return $a[0] },             1 ],
 [ sub { return @a[1, 2] },          2 ],
 [ sub { return @a[2 .. 4] },        3 ],
 [ sub { return @a[1, 4 .. 7, 2] },  6 ],
 [ sub { return @a[do{ 1 .. 5 }] },  5 ],
 [ sub { return @a[do{ 1 .. $x }] }, 'list' ],

 [ sub { return %h },              'list' ],
 [ sub { return $h{a} },           1 ],
 [ sub { return @h{qw/a b/} },     2 ],
 [ sub { return @h{@a[1 .. 3]} },  3 ],
 [ sub { return @h{@a[$y .. 3]} }, 'list' ],
 [ sub { return keys %h },         'list' ],
 [ sub { return values %h },       'list' ],

 [ sub { return $x, $a[3], $h{c} }, 3 ],
 [ sub { return $x, @a },           'list' ],
 [ sub { return %h, $y },           'list' ],

 [ sub { return 2 .. 4 },                  3 ],
 [ sub { return $x .. 3 },                 'list' ],
 [ sub { return 1 .. $x },                 'list' ],
 [ sub { return '2foo' .. 4 },             3 ],
 [ sub { my @a = (7, 8); return @a .. 4 }, 'list' ],
 [ sub { return do { return 1, 2 } .. 3 }, 2 ],
 [ sub { return 1 .. do { return 2, 3 } }, 2 ],
 [ sub { my @a = return 6, $x },           2 ],

 [ sub { for (1, 2, 3) { return } },                                     0 ],
 [ sub { for (1, 2, 3) { } return 1, 2; },                               2 ],
 [ sub { for (do { return 1, 2, 3 }) { } return 1, 2; },                 3 ],
 [ sub { for (do { return 2, 3 if $x }) { } },      { 2 => 0.5, 0 => 0.5 } ],
 [ sub { for (1, 2, 3) { return 1, 2 if $x } },                     'list' ],
 [ sub { for ($x, 1, $y) { return 1, 2 } },                              2 ],
 [ sub { for (@a) { return 1, do { $x } } },                             2 ],
 [ sub { for (keys %h) { return do { 1 }, do { return @a[0, 2] } } },    2 ],
 [ sub { for my $i (1 .. 4) { return @h{qw/a b/} } },                    2 ],
 [ sub { for (my $i; $i < 10; ++$i) { return 1, @a[do{return 2, 3}] } }, 2 ],
 [ sub { return 1, 2 for 1 .. 4 },                                       2 ],

 [ sub { while (1) { return } },                 0 ],
 [ sub { while (1) { } return 1, 2 },            2 ],
 [ sub { while (1) { return 1, 2 } },            2 ],
 [ sub { while (1) { return 1, 2 if $x } },      'list' ],
 [ sub { while (1) { last; return 1, 2 } },      2 ],
 [ sub { return 1, 2 while 1 },                  2 ],
 [ sub { while (do { return 2, 3 }) { } },       2 ],
 [ sub { while (do { return 2, 3 if $x }) { } }, 'list' ],

 [ sub { eval { return } },                         0 ],
 [ sub { eval { return 1, 2 } },                    2 ],
 [ sub { eval { }; return $x, 2 },                  2 ],
 [ sub { return eval { 1, $x }; },                  2 ],
 [ sub { return 1, eval { $x, eval { $h{foo} } } }, 3 ],
 [ sub { return eval { return $x, eval { $y } } },  2 ],
 [ sub { return eval { do { eval { @a } } } },      'list' ],

 [ sub { eval 'return 1, 2' }, 'list' ],
);

my $i = 1;
for (@tests) {
 my $r = $sn->nary($_->[0]);
 my $exp = ref $_->[1] ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'return test ' . $i);
 ++$i;
}
