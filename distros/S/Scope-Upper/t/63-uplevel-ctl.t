#!perl -T

use strict;
use warnings;

use Test::More tests => 3 + (3 + 4 + 4) + (3 + 4 + 4) + 5 + 3*3 + (4 + 7) + 1;

use Scope::Upper qw<uplevel HERE SUB CALLER>;

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
 my $desc = 'exception with no eval in between 1';
 local $@;
 eval {
  sub {
   is depth(), 2, "$desc: correct depth 1";
   uplevel {
    is depth(), 2, "$desc: correct depth 2";
    die 'cabbage';
   };
   fail "$desc: not reached 1";
  }->();
  fail "$desc: not reached 2";
 };
 my $line = __LINE__-6;
 like $@, qr/^cabbage at \Q$0\E line $line/, "$desc: correct exception";
}

{
 my $desc = 'exception with no eval in between 2';
 local $@;
 eval {
  sub {
   is depth(), 2, "$desc: correct depth 1";
   uplevel {
    is depth(), 2, "$desc: correct depth 2";
    sub {
     is depth(), 3, "$desc: correct depth 3";
     die 'lettuce';
    }->();
   };
   fail "$desc: not reached 1";
  }->();
  fail "$desc: not reached 2";
 };
 my $line = __LINE__-7;
 like $@, qr/^lettuce at \Q$0\E line $line/, "$desc: correct exception";
}

{
 my $desc = 'exception with no eval in between 3';
 local $@;
 eval q[
  sub {
   is depth(), 2, "$desc: correct depth 1";
   uplevel {
    is depth(), 2, "$desc: correct depth 2";
    sub {
     is depth(), 3, "$desc: correct depth 3";
     die 'onion';
    }->();
   };
   fail "$desc: not reached 1";
  }->();
  fail "$desc: not reached 2";
 ];
 my $loc = $^P ? "[$0:" . (__LINE__-14) . ']' : '';
 like $@, qr/^onion at \(eval \d+\)\Q$loc\E line 8/, "$desc: correct exception";
}

{
 my $desc = 'exception with an eval in between 1';
 local $@;
 eval {
  sub {
   eval {
    is depth(), 3, "$desc: correct depth 1";
    uplevel {
     is depth(), 2, "$desc: correct depth 2";
     die 'macaroni';
    } SUB;
    fail "$desc: not reached 1";
   };
   fail "$desc: not reached 2";
  }->();
  fail "$desc: not reached 3";
 };
 my $line = __LINE__-8;
 like $@, qr/^macaroni at \Q$0\E line $line/, "$desc: correct exception";
}

{
 my $desc = 'exception with an eval in between 2';
 local $@;
 eval {
  sub {
   eval {
    is depth(), 3, "$desc: correct depth 1";
    uplevel {
     is depth(), 2, "$desc: correct depth 1";
     sub {
      is depth(), 3, "$desc: correct depth 1";
      die 'spaghetti';
     }->();
    } SUB;
    fail "$desc: not reached 1";
   };
   fail "$desc: not reached 2";
  }->();
  fail "$desc: not reached 3";
 };
 my $line = __LINE__-9;
 like $@, qr/^spaghetti at \Q$0\E line $line/, "$desc: correct exception";
}

{
 my $desc = 'exception with an eval in between 3';
 local $@;
 eval {
  sub {
   eval q[
    is depth(), 3, "$desc: correct depth 1";
    uplevel {
     is depth(), 2, "$desc: correct depth 1";
     sub {
      is depth(), 3, "$desc: correct depth 1";
      die 'ravioli';
     }->();
    } SUB;
    fail "$desc: not reached 1";
    ];
   fail "$desc: not reached 2";
  }->();
  fail "$desc: not reached 3";
 };
 my $loc = $^P ? "[$0:" . (__LINE__-15) . ']' : '';
 like $@, qr/^ravioli at \(eval \d+\)\Q$loc\E line 7/,
                                                     "$desc: correct exception";
}
our $hurp;

SKIP: {
 skip "Causes failures during global destruction on perl 5.8.[0-6]" => 5
                                         if "$]" >= 5.008 and "$]" <= 5.008_006;
 my $desc = 'exception with an eval and a local $@ in between';
 local $hurp = 'durp';
 local $@;
 my $x = (eval {
  sub {
   local $@;
   eval {
    sub {
     is depth(), 4, "$desc: correct depth 1";
     uplevel {
      is depth(), 2, "$desc: correct depth 2";
      die 'lasagna'
     } CALLER(2);
     fail "$desc: not reached 1";
    }->();
    fail "$desc: not reached 2";
   };
   fail "$desc: not reached 3";
  }->();
  fail "$desc: not reached 4";
 }, $@);
 my $line = __LINE__-10;
 like $@, qr/^lasagna at \Q$0\E line $line/, "$desc: correct exception";
 like $x, qr/^lasagna at \Q$0\E line $line/, "$desc: \$@ timely reset";
 is $hurp, 'durp', "$desc: force save stack flushing didn't go too far";
}

{
 my $desc = 'several exceptions in a row';
 local $@;
 eval {
  sub {
   is depth(), 2, "$desc (first): correct depth";
   uplevel {
    is depth(), 2, "$desc (first): correct depth";
    die 'carrot';
   };
   fail "$desc (first): not reached 1";
  }->();
  fail "$desc (first): not reached 2";
 };
 my $line = __LINE__-6;
 like $@, qr/^carrot at \Q$0\E line $line/, "$desc (first): correct exception";
 eval {
  sub {
   is depth(), 2, "$desc (second): correct depth 1";
   uplevel {
    is depth(), 2, "$desc (second): correct depth 2";
    die 'potato';
   };
   fail "$desc (second): not reached 1";
  }->();
  fail "$desc (second): not reached 2";
 };
 $line = __LINE__-6;
 like $@, qr/^potato at \Q$0\E line $line/, "$desc (second): correct exception";
 eval {
  sub {
   is depth(), 2, "$desc (third): correct depth 1";
   uplevel {
    is depth(), 2, "$desc (third): correct depth 2";
    die 'tomato';
   };
   fail "$desc (third): not reached 1";
  }->();
  fail "$desc (third): not reached 2";
 };
 $line = __LINE__-6;
 like $@, qr/^tomato at \Q$0\E line $line/, "$desc (third): correct exception";
}

my $has_B = do { local $@; eval { require B; 1 } };

sub check_depth {
 my ($code, $expected, $desc) = @_;

 SKIP: {
  skip 'B.pm is needed to check CV depth' => 1 unless $has_B;

  local $Test::Builder::Level = ($Test::Builder::Level || 0) + 1;

  my $depth = B::svref_2object($code)->DEPTH;
  is $depth, $expected, $desc;
 }
}

sub bonk {
 my ($code, $n, $cxt) = @_;
 $cxt = SUB unless defined $cxt;
 if ($n) {
  bonk($code, $n - 1, $cxt);
 } else {
  &uplevel($code, $cxt);
 }
}

{
 my $desc = "an exception unwinding several levels of the same sub 1";
 local $@;
 check_depth \&bonk, 0, "$desc: depth at the beginning";
 my $rec = 7;
 sub {
  eval {
   bonk(sub {
    check_depth \&bonk, $rec + 1, "$desc: depth inside";
    die 'pepperoni';
   }, $rec);
  }
 }->();
 my $line = __LINE__-4;
 like $@, qr/^pepperoni at \Q$0\E line $line/, "$desc: correct exception";
 check_depth \&bonk, 0, "$desc: depth at the end";
}

sub clash {
 my ($pre, $rec, $desc, $cxt, $m, $n) = @_;
 $m = 0 unless defined $m;
 if ($m < $pre) {
  clash($pre, $rec, $desc, $cxt, $m + 1, $n);
 } elsif ($m == $pre) {
  check_depth \&clash, $pre + 1, "$desc: depth after prepending frames";
  eval {
   clash($pre, $rec, $desc, $cxt, $pre + 1, $n);
  };
  my $line = __LINE__+11;
  like $@, qr/^garlic at \Q$0\E line $line/, "$desc: correct exception";
  check_depth \&clash, $pre + 1, "$desc: depth after unwinding";
 } else {
  $n   = 0   unless defined $n;
  $cxt = SUB unless defined $cxt;
  if ($n < $rec) {
   clash($pre, $rec, $desc, $cxt, $m, $n + 1);
  } else {
   uplevel {
    check_depth \&clash, $pre + 1 + $rec + 1, "$desc: depth inside";
    die 'garlic';
   } $cxt;
  }
 }
}

{
 my $desc = "an exception unwinding several levels of the same sub 2";
 local $@;
 check_depth \&clash, 0, "$desc: depth at the beginning";
 my $pre = 5;
 my $rec = 10;
 sub {
  eval {
   clash($pre, $rec, $desc);
  }
 }->();
 is $@, '', "$desc: no exception outside";
 check_depth \&clash, 0, "$desc: depth at the beginning";
}

# XS

{
 my $desc = 'exception thrown from XS';
 local $@;
 eval {
  sub {
   &uplevel(\&uplevel => \1, HERE);
  }->();
 };
 my $line = $^P ? '\d+' : __LINE__-2; # The error happens at the target frame.
 my $file = $^P ? '\S+' : quotemeta $0;
 like $@,
   qr/^First argument to uplevel must be a code reference at $file line $line/,
   "$desc: correct error";
}
