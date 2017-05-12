#!perl -T

use strict;
use warnings;

use Test::More tests => 3 + 7 * 2 + 8;

use Scope::Upper qw<uplevel HERE UP>;

sub depth {
 my $depth = 0;
 while (1) {
  my @c = caller($depth);
  last unless @c;
  ++$depth;
 }
 return $depth - 1;
}

is depth(),                           0, 'check top depth';
is sub { depth() }->(),               1, 'check subroutine call depth';
is do { local $@; eval { depth() } }, 1, 'check eval block depth';

{
 my $desc = 'uplevel in uplevel : lower frame';
 local $@;
 my @ret = eval {
  1, sub {
   is depth(), 2, "$desc: correct depth 1";
   2, uplevel(sub {
    is depth(), 2, "$desc: correct depth 2";
    3, sub {
     is depth(), 3, "$desc: correct depth 3";
     4, uplevel(sub {
      is depth(), 3, "$desc: correct depth 4";
      return 5, @_;
     }, 6, @_, HERE);
    }->(7, @_);
   }, 8, @_, HERE);
  }->(9);
 };
 is $@,      '',              "$desc: no error";
 is depth(), 0,               "$desc: correct depth outside";
 is_deeply \@ret, [ 1 .. 9 ], "$desc: correct return value"
}

{
 my $desc = 'uplevel in uplevel : same frame';
 local $@;
 my @ret = eval {
  11, sub {
   is depth(), 2, "$desc: correct depth 1";
   12, uplevel(sub {
    is depth(), 2, "$desc: correct depth 2";
    13, sub {
     is depth(), 3, "$desc: correct depth 3";
     14, uplevel(sub {
      is depth(), 2, "$desc: correct depth 4";
      return 15, @_;
     }, 16, @_, UP);
    }->(17, @_);
   }, 18, @_, HERE);
  }->(19);
 };
 is $@,      '',                "$desc: no error";
 is depth(), 0,                 "$desc: correct depth outside";
 is_deeply \@ret, [ 11 .. 19 ], "$desc: correct return value"
}

{
 my $desc = 'uplevel in uplevel : higher frame';
 local $@;
 my @ret = eval {
  20, sub {
   is depth(), 2, "$desc: correct depth 1";
   21, sub {
    is depth(), 3, "$desc: correct depth 2";
    22, uplevel(sub {
     is depth(), 3, "$desc: correct depth 3";
     23, sub {
      is depth(), 4, "$desc: correct depth 4";
      24, uplevel(sub {
       is depth(), 2, "$desc: correct depth 5";
       return 25, @_;
      }, 26, @_, UP UP);
     }->(27, @_);
    }, 28, @_, HERE);
   }->(29, @_);
  }->('2A');
 };
 is $@,      '',                      "$desc: no error";
 is depth(), 0,                       "$desc: correct depth outside";
 is_deeply \@ret, [ 20 .. 29, '2A' ], "$desc: correct return value"
}
