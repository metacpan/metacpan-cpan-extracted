#!perl -T

use strict;
use warnings;

use Test::More tests => 33;

use Scope::Upper qw<unwind SUB>;

my ($res, @res);

# --- Void to void ------------------------------------------------------------

sub {
 $res = 1;
 unwind(qw<a b c> => SUB);
 $res = 0;
}->(0);
ok $res, 'unwind in void context at sub to void';

sub {
 $res = 1;
 eval {
  unwind(qw<d e f> => SUB);
 };
 $res = 0;
}->(0);
ok $res, 'unwind in void context at sub across eval to void';

sub {
 $res = 1;
 for (1 .. 5) {
  unwind qw<g h i> => SUB;
 }
 $res = 0;
}->(0);
ok $res, 'unwind in void context at sub across loop to void';

# --- Void to scalar ----------------------------------------------------------

$res = sub {
 unwind(qw<a b c> => SUB);
 return 'XXX';
}->(0);
is $res, 'c', 'unwind in void context at sub to scalar';

$res = sub {
 eval {
  unwind qw<d e f> => SUB;
 };
 return 'XXX';
}->(0);
is $res, 'f', 'unwind in void context at sub across eval to scalar';

$res = sub {
 for (1 .. 5) {
  unwind qw<g h i> => SUB;
 }
}->(0);
is $res, 'i', 'unwind in void context at sub across loop to scalar';

$res = sub {
 for (6, unwind qw<j k l> => SUB) {
  $res = 'NO';
 }
 return 'XXX';
}->(0);
is $res, 'l', 'unwind in void context at sub across loop iterator to scalar';

# --- Void to list ------------------------------------------------------------

@res = sub {
 unwind qw<a b c> => SUB;
 return 'XXX';
}->(0);
is_deeply \@res, [ qw<a b c> ], 'unwind in void context at sub to list';

@res = sub {
 eval {
  unwind qw<d e f> => SUB;
 };
 return 'XXX';
}->(0);
is_deeply \@res, [ qw<d e f> ], 'unwind in void context at sub across eval to list';

@res = sub {
 for (1 .. 5) {
  unwind qw<g h i> => SUB;
 }
}->(0);
is_deeply \@res, [ qw<g h i> ], 'unwind in void context at sub across loop to list';

# --- Scalar to void ----------------------------------------------------------

sub {
 $res = 1;
 my $temp = unwind(qw<a b c> => SUB);
 $res = 0;
}->(0);
ok $res, 'unwind in scalar context at sub to void';

sub {
 $res = 1;
 my $temp = eval {
  unwind(qw<d e f> => SUB);
 };
 $res = 0;
}->(0);
ok $res, 'unwind in scalar context at sub across eval to void';

sub {
 $res = 1;
 for (1 .. 5) {
  my $temp = (unwind qw<g h i> => SUB);
 }
 $res = 0;
}->(0);
ok $res, 'unwind in scalar context at sub across loop to void';

sub {
 $res = 1;
 if (unwind qw<m n o> => SUB) {
  $res = undef;
 }
 $res = 0;
}->(0);
ok $res, 'unwind in scalar context at sub across test to void';

# --- Scalar to scalar --------------------------------------------------------

$res = sub {
 1, unwind(qw<a b c> => SUB);
}->(0);
is $res, 'c', 'unwind in scalar context at sub to scalar';

$res = sub {
 eval {
  8, unwind qw<d e f> => SUB;
 };
}->(0);
is $res, 'f', 'unwind in scalar context at sub across eval to scalar';

$res = sub {
 if (unwind qw<m n o> => SUB) {
  return 'XXX';
 }
}->(0);
is $res, 'o', 'unwind in scalar context at sub across test to scalar';

# --- Scalar to list ----------------------------------------------------------

@res = sub {
 if (unwind qw<m n o> => SUB) {
  return 'XXX';
 }
}->(0);
is_deeply \@res, [ qw<m n o> ], 'unwind in scalar context at sub across test to list';

# --- List to void ------------------------------------------------------------

sub {
 $res = 1;
 my @temp = unwind(qw<a b c> => SUB);
 $res = 0;
}->(0);
ok $res, 'unwind in list context at sub to void';

sub {
 $res = 1;
 my @temp = eval {
  unwind(qw<d e f> => SUB);
 };
 $res = 0;
}->(0);
ok $res, 'unwind in list context at sub across eval to void';

sub {
 $res = 1;
 for (1 .. 5) {
  my @temp = (unwind qw<g h i> => SUB);
 }
 $res = 0;
}->(0);
ok $res, 'unwind in list context at sub across loop to void';

sub {
 $res = 1;
 for (6, unwind qw<j k l> => SUB) {
  $res = undef;
 }
 $res = 0;
}->(0);
ok $res, 'unwind in list context at sub across test to void';

# --- List to scalar ----------------------------------------------------------

$res = sub {
 my @temp = (1, unwind(qw<a b c> => SUB));
 return 'XXX';
}->(0);
is $res, 'c', 'unwind in list context at sub to scalar';

$res = sub {
 my @temp = eval {
  8, unwind qw<d e f> => SUB;
 };
 return 'XXX';
}->(0);
is $res, 'f', 'unwind in list context at sub across eval to scalar';

$res = sub {
 for (1 .. 5) {
  my @temp = (7, unwind qw<g h i> => SUB);
 }
 return 'XXX';
}->(0);
is $res, 'i', 'unwind in list context at sub across loop to scalar';

$res = sub {
 for (6, unwind qw<j k l> => SUB) {
  return 'XXX';
 }
}->(0);
is $res, 'l', 'unwind in list context at sub across loop iterator to scalar';

# --- List to list ------------------------------------------------------------

@res = sub {
 2, unwind qw<a b c> => SUB;
}->(0);
is_deeply \@res, [ qw<a b c> ], 'unwind in list context at sub to list';

@res = sub {
 eval {
  8, unwind qw<d e f> => SUB;
 };
}->(0);
is_deeply \@res, [ qw<d e f> ], 'unwind in list context at sub across eval to list';

@res = sub {
 for (6, unwind qw<j k l> => SUB) {
  return 'XXX';
 }
}->(0);
is_deeply \@res, [ qw<j k l> ], 'unwind in list context at sub across loop iterator to list';

# --- Prototypes --------------------------------------------------------------

sub pie { 7, unwind qw<pie good>, $_[0] => SUB }

sub wlist (@) { return @_ }

$res = wlist pie 1;
is $res, 3, 'unwind to list prototype to scalar';

@res = wlist pie 2;
is_deeply \@res, [ qw<pie good 2> ], 'unwind to list prototype to list';

sub wscalar ($$) { return @_ }

$res = wscalar pie(6), pie(7);
is $res, 2, 'unwind to scalar prototype to scalar';

@res = wscalar pie(8), pie(9);
is_deeply \@res, [ 8, 9 ], 'unwind to scalar prototype to list';

