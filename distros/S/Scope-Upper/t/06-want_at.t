#!perl -T

use strict;
use warnings;

use Test::More tests => 18;

use Scope::Upper qw<want_at UP HERE>;

sub check {
 my ($w, $exp, $desc) = @_;
 my $cx = sub {
  my $a = shift;
  if (!defined $a) {
   return 'void';
  } elsif ($a) {
   return 'list';
  } else {
   return 'scalar';
  }
 };
 is $cx->($w), $cx->($exp), $desc;
}

my $w;

check want_at,       undef, 'main : want_at';
check want_at(HERE), undef, 'main : want_at HERE';
check want_at(-1),   undef, 'main : want_at -1';

my @a = sub {
 check want_at, 1, 'sub0 : want_at';
 {
  check want_at,     1, 'sub : want_at';
  check want_at(UP), 1, 'sub : want_at UP';
  for (1) {
   check want_at,        1, 'for : want_at';
   check want_at(UP),    1, 'for : want_at UP';
   check want_at(UP UP), 1, 'for : want_at UP UP';
  }
  eval "
   check want_at,        undef, 'eval string : want_at';
   check want_at(UP),    1,     'eval string : want_at UP';
   check want_at(UP UP), 1,     'eval string : want_at UP UP';
  ";
  my $x = eval {
   do {
    check want_at,        0, 'do : want_at';
    check want_at(UP),    0, 'do : want_at UP';
    check want_at(UP UP), 1, 'do : want_at UP UP';
   };
   check want_at,        0, 'eval : want_at';
   check want_at(UP),    1, 'eval : want_at UP';
   check want_at(UP UP), 1, 'eval : want_at UP UP';
  };
 }
}->();
