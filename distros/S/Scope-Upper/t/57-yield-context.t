#!perl -T

use strict;
use warnings;

use Test::More tests => 33;

use Scope::Upper qw<yield HERE SCOPE SUB>;

my ($res, @res);

# --- Void to void ------------------------------------------------------------

do {
 $res = 1;
 yield(qw<a b c> => HERE);
 $res = 0;
};
ok $res, 'yield in void context at sub to void';

do {
 $res = 1;
 eval {
  yield(qw<d e f> => SCOPE(1));
 };
 $res = 0;
};
ok $res, 'yield in void context at sub across eval to void';

do {
 $res = 1;
 for (1 .. 5) {
  yield qw<g h i> => SCOPE(1);
 }
 $res = 0;
};
ok $res, 'yield in void context at sub across loop to void';

# --- Void to scalar ----------------------------------------------------------

$res = do {
 yield(qw<a b c> => HERE);
 return 'XXX';
};
is $res, 'c', 'yield in void context at sub to scalar';

$res = do {
 eval {
  yield qw<d e f> => SCOPE(1);
 };
 return 'XXX';
};
is $res, 'f', 'yield in void context at sub across eval to scalar';

$res = do {
 for (1 .. 5) {
  yield qw<g h i> => SCOPE(1);
 }
};
is $res, 'i', 'yield in void context at sub across loop to scalar';

$res = do {
 for (6, yield qw<j k l> => SCOPE(0)) {
  $res = 'NO';
 }
 'XXX';
};
is $res, 'l', 'yield in void context at sub across loop iterator to scalar';

# --- Void to list ------------------------------------------------------------

@res = do {
 yield qw<a b c> => HERE;
 return 'XXX';
};
is_deeply \@res, [ qw<a b c> ], 'yield in void context at sub to list';

@res = do {
 eval {
  yield qw<d e f> => SCOPE(1);
 };
 'XXX';
};
is_deeply \@res, [ qw<d e f> ], 'yield in void context at sub across eval to list';

@res = do {
 for (1 .. 5) {
  yield qw<g h i> => SCOPE(1);
 }
};
is_deeply \@res, [ qw<g h i> ], 'yield in void context at sub across loop to list';

# --- Scalar to void ----------------------------------------------------------

do {
 $res = 1;
 my $temp = yield(qw<a b c> => HERE);
 $res = 0;
};
ok $res, 'yield in scalar context at sub to void';

do {
 $res = 1;
 my $temp = eval {
  yield(qw<d e f> => SCOPE(1));
 };
 $res = 0;
};
ok $res, 'yield in scalar context at sub across eval to void';

do {
 $res = 1;
 for (1 .. 5) {
  my $temp = (yield qw<g h i> => SCOPE(1));
 }
 $res = 0;
};
ok $res, 'yield in scalar context at sub across loop to void';

do {
 $res = 1;
 if (yield qw<m n o> => SCOPE(0)) {
  $res = undef;
 }
 $res = 0;
};
ok $res, 'yield in scalar context at sub across test to void';

# --- Scalar to scalar --------------------------------------------------------

$res = sub {
 1, yield(qw<a b c> => HERE);
}->(0);
is $res, 'c', 'yield in scalar context at sub to scalar';

$res = sub {
 eval {
  8, yield qw<d e f> => SCOPE(1);
 };
}->(0);
is $res, 'f', 'yield in scalar context at sub across eval to scalar';

$res = sub {
 if (yield qw<m n o> => SCOPE(0)) {
  return 'XXX';
 }
}->(0);
is $res, 'o', 'yield in scalar context at sub across test to scalar';

# --- Scalar to list ----------------------------------------------------------

@res = sub {
 if (yield qw<m n o> => SCOPE(0)) {
  return 'XXX';
 }
}->(0);
is_deeply \@res, [ qw<m n o> ], 'yield in scalar context at sub across test to list';

# --- List to void ------------------------------------------------------------

do {
 $res = 1;
 my @temp = yield(qw<a b c> => HERE);
 $res = 0;
};
ok $res, 'yield in list context at sub to void';

do {
 $res = 1;
 my @temp = eval {
  yield(qw<d e f> => SCOPE(1));
 };
 $res = 0;
};
ok $res, 'yield in list context at sub across eval to void';

do {
 $res = 1;
 for (1 .. 5) {
  my @temp = (yield qw<g h i> => SCOPE(1));
 }
 $res = 0;
};
ok $res, 'yield in list context at sub across loop to void';

do {
 $res = 1;
 for (6, yield qw<j k l> => SCOPE(0)) {
  $res = undef;
 }
 $res = 0;
};
ok $res, 'yield in list context at sub across test to void';

# --- List to scalar ----------------------------------------------------------

$res = do {
 my @temp = (1, yield(qw<a b c> => HERE));
 'XXX';
};
is $res, 'c', 'yield in list context at sub to scalar';

$res = do {
 my @temp = eval {
  8, yield qw<d e f> => SCOPE(1);
 };
 'XXX';
};
is $res, 'f', 'yield in list context at sub across eval to scalar';

$res = do {
 for (1 .. 5) {
  my @temp = (7, yield qw<g h i> => SCOPE(1));
 }
 'XXX';
};
is $res, 'i', 'yield in list context at sub across loop to scalar';

$res = sub {
 for (6, yield qw<j k l> => SCOPE(0)) {
  return 'XXX';
 }
}->(0);
is $res, 'l', 'yield in list context at sub across loop iterator to scalar';

# --- List to list ------------------------------------------------------------

@res = do {
 2, yield qw<a b c> => HERE;
};
is_deeply \@res, [ qw<a b c> ], 'yield in list context at sub to list';

@res = do {
 eval {
  8, yield qw<d e f> => SCOPE(1);
 };
};
is_deeply \@res, [ qw<d e f> ], 'yield in list context at sub across eval to list';

@res = sub {
 for (6, yield qw<j k l> => SCOPE(0)) {
  return 'XXX';
 }
}->(0);
is_deeply \@res, [ qw<j k l> ], 'yield in list context at sub across loop iterator to list';

# --- Prototypes --------------------------------------------------------------

sub pie { 7, yield qw<pie good>, $_[0] => SUB }

sub wlist (@) { return @_ }

$res = wlist pie 1;
is $res, 3, 'yield to list prototype to scalar';

@res = wlist pie 2;
is_deeply \@res, [ qw<pie good 2> ], 'yield to list prototype to list';

sub wscalar ($$) { return @_ }

$res = wscalar pie(6), pie(7);
is $res, 2, 'yield to scalar prototype to scalar';

@res = wscalar pie(8), pie(9);
is_deeply \@res, [ 8, 9 ], 'yield to scalar prototype to list';

