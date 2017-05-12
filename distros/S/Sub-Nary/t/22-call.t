#!perl -T

use strict;
use warnings;

use Test::More tests => 43;

use Sub::Nary;

my $sn = Sub::Nary->new();

my $x;

sub CORE::GLOBAL::reset {
 return 1, 2, 3
}

sub zero { }
sub one  { 1 }
sub two  { 1, 2 }
sub lots { @_ }

sub rec { rec(); }

sub rec1 { rec2(); }
sub rec2 { rec1(); }

my @tests = (
 [ sub { hlaghlaghlagh() }, 'list' ],

 [ sub { zero }, 0 ],
 [ sub { one  }, 1 ],
 [ sub { two  }, 2 ],
 [ sub { lots }, 'list' ],

 [ sub { one, zero, two }, 3 ],
 [ sub { one, lots },      'list' ],
 [ sub { lots, two },      'list' ],

 [ sub { do { one, do { two } } },  3 ],
 [ sub { do { lots, do { one } } }, 'list' ],

 [ sub { 1, return two, do { 4 } },         3 ],
 [ sub { two 1, return 2 },                 1 ],
 [ sub { two 1, do { return 5 if $x; 3 } }, { 1 => 0.5, 2 => 0.5 } ],

 [ sub { 1, one(), 2 },   3 ],
 [ sub { 1, one(), @_ },  'list' ],
 [ sub { $_[0], two() },  3 ],
 [ sub { my $x = two() }, 1 ],
 [ sub { my @a = two() }, 2 ],

 [ sub { 1, do { two, 1 }, do { one }, @_[0, 1] }, 7 ],
 [ sub { 1, do { two, 1, do { one, @_[0, 1] } } }, 7 ],

 [ sub { $_[0]->what },                'list' ],
 [ sub { my $m = $_[1]; $_[0]->$m() }, 'list' ],
 [ sub { $_[0]->() },                  'list' ],
 [ sub { &two },                       2 ],
 [ sub { goto &two },                  2 ],
 [ sub { my $x = $_[0]; goto &$x },    'list' ],
 [ sub { FOO: goto FOO, 1 },           'list' ],

 [ sub { rec() },                      'list' ],
 [ sub { rec1() },                     'list' ],

 [ sub { sub { 1, 2 }, 2, 3 },                                      3 ],
 [ sub { sub { 1, 2 }->() },                                        2 ],
 [ sub { sub { 1, 2 }->(), 1, 2 },                                  4 ],
 [ sub { do { sub { 1, 2 } }->(), 3 },                              3 ],
 [ sub { do { my $x = sub { }; sub { 1, 2 } }->(), 3 },             3 ],
 [ sub { do { my $x = \&zero; sub { 1, 2 } }->(), 3 },              3 ],
 [ sub { do { my $x = 1; do { my $y = 2; sub { 1, 2 } } }->(), 3 }, 3 ],
 [ sub { sub { sub { 1, 2 } }->()->() },                            'list' ],
 [ sub { sub { sub { 1, 2 }->(), 3 }->(), 4 },                      4 ],

 [ sub { \&zero },          1 ],
 [ sub { *zero },           1 ],
 [ sub { *zero{CODE}->() }, 'list' ],

 [ sub { &CORE::GLOBAL::shift }, 'list' ],
 [ sub { &CORE::GLOBAL::reset }, 3 ],
);

my $i = 1;
for (@tests) {
 my $r = $sn->nary($_->[0]);
 my $exp = ref $_->[1] ? $_->[1] : { $_->[1] => 1 };
 is_deeply($r, $exp, 'call test ' . $i);
 ++$i;
}
