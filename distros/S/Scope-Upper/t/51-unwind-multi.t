#!perl -T

use strict;
use warnings;

use Test::More tests => 13 + 3;

use Scope::Upper qw<unwind SCOPE CALLER>;

my ($l1, $l2);

our $x;

sub c {
 $x = 3;
 sub {
  unwind("eval", eval {
   do {
    for (3, 4, 5) {
     1, unwind('from', 'the', 'sub', 'c' => SCOPE $l1);
    }
   }
  } => SCOPE $l2);
 }->(2, 3, 4);
 return 'in c'
}

sub b {
 local $x = 2;
 my @c = (1 .. 12, c());
 is $x, 3, '$x in b after c()';
 return @c, 'in b';
}

sub a {
 local $x = 1;
 my @b = b();
 is $x, 1, '$x in a after b()';
 return @b, 'in a';
}

$l1 = 0;
$l2 = 0;
is_deeply [ a() ], [ 1 .. 12, 'in c', 'in b', 'in a' ],
          'l1=0, l2=0';

$l1 = 0;
$l2 = 1;
is_deeply [ a() ], [ 1 .. 12, qw<eval from the sub c>, 'in b', 'in a' ],
          'l1=0, l2=1';

$l1 = 0;
$l2 = 2;
is_deeply [ a() ], [ qw<eval from the sub c>, 'in a' ],
          'l1=0, l2=2';

$l1 = 4;
$l2 = 999;
is_deeply [ a() ], [ 1 .. 12, qw<from the sub c>, 'in b', 'in a' ],
          'l1=4, l2=?';

$l1 = 5;
$l2 = 999;
is_deeply [ a() ], [ qw<from the sub c>, 'in a' ],
          'l1=5, l2=?';

# Unwinding while unwinding
{
 package Scope::Upper::TestGuard;

 sub new {
  my $class = shift;
  bless { cb => $_[0] }, $class;
 }

 sub DESTROY {
  $_[0]->{cb}->()
 }
}

{
 my $desc = 'unwinding while unwinding';
 local $@;

 eval {
  my @res = sub {
   sub {
    my $guard = Scope::Upper::TestGuard->new(sub {
     my @res = sub {
      sub {
       unwind @_ => CALLER(1);
      }->(@_);
      fail "$desc (second): not reached";
     }->(qw<a b c>);
     is_deeply \@res, [ qw<a b c> ], "$desc (second): correct returned values";
    });
    unwind @_ => CALLER(1);
   }->(@_);
   fail "$desc (first): not reached";
  }->(qw<y z>);
  is_deeply \@res, [ qw<y z> ], "$desc (first): correct returned values";
 };
 is $@, '', "$desc: did not croak";
}
