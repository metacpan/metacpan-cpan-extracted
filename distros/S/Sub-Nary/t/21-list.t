#!perl -T

use strict;
use warnings;

use Test::More tests => 44;

use Sub::Nary;

my $sn = Sub::Nary->new();

my ($x, $y, @a, %h);

my @tests = (
 [ sub { },                   0 ],
 [ sub { () },                0 ],
 [ sub { (1, 2, 3)[2 .. 1] }, 0 ],

 [ sub { 1 },                               1 ],
 [ sub { 1, 2 },                            2 ],
 [ sub { my $x = 1; $x = 2; 3, 4, 5; },     3 ],
 [ sub { do { 1; 2, 3 } },                  2 ],
 [ sub { do { 1; 2, do { 3, do { 4 } } } }, 3 ],

 [ sub { $x },     1 ],
 [ sub { $x, $y }, 2 ],

 [ sub { @a },               'list' ],
 [ sub { $a[0] },            1 ],
 [ sub { @a[1, 2] },         2 ],
 [ sub { @a[2 .. 4] },       3 ],
 [ sub { @a[1, 4 .. 7, 2] }, 6 ],

 [ sub { %h },          'list' ],
 [ sub { $h{a} },       1 ],
 [ sub { @h{qw/a b/} }, 2 ],
 [ sub { keys %h },     'list' ],
 [ sub { values %h },   'list' ],

 [ sub { $x, $a[3], $h{c} }, 3 ],
 [ sub { $x, @a },           'list' ],
 [ sub { %h, $y },           'list' ],

 [ sub { 2 .. 4 },                      3 ],
 [ sub { $x .. 3 },                     'list' ],
 [ sub { 1 .. $x },                      'list' ],
 [ sub { '2foo' .. 4 },                  3 ],
 [ sub { my @a = (7, 8); @a .. 4 },      'list' ],
 [ sub { my @a = (2 .. 5) },             4 ],
 [ sub { my @b; my @a = @b = (2 .. 5) }, 4 ],
 [ sub { my @a =()= (2 .. 5) },          0 ],
 [ sub { my $x =()= (2 .. 5) },          1 ],

 [ sub { "banana" =~ /(a)/g }, 'list' ],

 [ sub { (localtime)[0, 1, 2] }, 3 ],

 [ sub { for (1, 2, 3) { } },         0 ],
 [ sub { for (1, 2, 3) { 1; } 1, 2 }, 2 ],

 [ sub { while (1) { } },         0 ],
 [ sub { while (1) { 1; } 1, 2 }, 2 ],

 [ sub { eval { } },                          0 ],
 [ sub { eval { 1, 2 } },                     2 ],
 [ sub { eval { }; $x, 2 },                   2 ],
 [ sub { 1, eval { $x, eval { $h{foo} } } },  3 ],
 [ sub { eval { 1, do { eval { @a }, 2 } } }, 'list' ],

 [ sub { eval '1, 2' }, 'list' ],
);

my $i = 1;
for (@tests) {
 my $r = $sn->nary($_->[0]);
 my $exp = ref $_->[1] ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'list test ' . $i);
 ++$i;
}
