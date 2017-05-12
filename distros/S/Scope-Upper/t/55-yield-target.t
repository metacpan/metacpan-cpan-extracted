#!perl -T

use strict;
use warnings;

use Test::More tests => 18;

use Scope::Upper qw<yield leave>;

my @res;

@res = (0, eval {
 yield;
 1;
}, 2);
is $@, '', 'yield() does not croak';
is_deeply \@res, [ 0, 2 ], 'yield() in eval { ... }';

@res = (3, eval "
 yield;
 4;
", 5);
is $@, '', 'yield() does not croak';
is_deeply \@res, [ 3, 5 ], 'yield() in eval "..."';

@res = (6, sub {
 yield;
 7;
}->(), 8);
is_deeply \@res, [ 6, 8 ], 'yield() in sub { ... }';

@res = (9, do {
 yield;
 10;
}, 11);
is_deeply \@res, [ 9, 11 ], 'yield() in do { ... }';

@res = (12, (map {
 yield;
 13;
} qw<a b c>), 14);
is_deeply \@res, [ 12, 14 ], 'yield() in map { ... }';

my $loop;
@res = (15, do {
 for (16, 17) {
  $loop = $_;
  yield;
  my $x = 18;
 }
}, 19);
is $loop, 16, 'yield() exited for';
is_deeply \@res, [ 15, 19 ], 'yield() in for () { ... }';

@res = (20, do {
 $loop = 21;
 while ($loop) {
  yield;
  $loop = 0;
  my $x = 22;
 }
}, 23);
is $loop, 21, 'yield() exited while';
is_deeply \@res, [ 20, 23 ], 'yield() in while () { ... }';

SKIP: {
 skip '"eval { $str =~ s/./die q[foo]/e }" breaks havoc on perl 5.8 and below'
                                                           => 1 if "$]" < 5.010;
 my $s = 'a';
 local $@;
 eval {
  $s =~ s/./yield; die 'not reached'/e;
 };
 my $err  = $@;
 my $line = __LINE__-3;
 like $err,
      qr/^yield\(\) can't target a substitution context at \Q$0\E line $line/,
      'yield() cannot exit subst';
}

SKIP: {
 skip 'perl 5.10 is required to test interaction with given/when' => 6
                                                                if "$]" < 5.010;

 @res = eval <<'TESTCASE';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  (24, do {
   given (25) {
    yield;
    my $x = 26;
   }
  }, 27);
TESTCASE
 diag $@ if $@;
 is_deeply \@res, [ 24, 27 ], 'yield() in given { }';

 # Beware that calling yield() in when() in given() sends us directly at the
 # end of the enclosing given block.
 @res = ();
 eval <<'TESTCASE';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  @res = (28, do {
   given (29) {
    when (29) {
     yield;
     die 'not reached 1';
    }
    die 'not reached 2';
   }
  }, 30)
TESTCASE
 is $@, '', 'yield() in when { } in given did not croak';
 is_deeply \@res, [ 28, 30 ], 'yield() in when { } in given';

 # But calling yield() in when() in for() sends us at the next iteration.
 @res = ();
 eval <<'TESTCASE';
  BEGIN {
   if ("$]" >= 5.017_011) {
    require warnings;
    warnings->unimport('experimental::smartmatch');
   }
  }
  use feature 'switch';
  @res = (31, do {
   for (32, 33) {
    $loop = $_;
    when (32) {
     yield;
     die 'not reached 3';
     my $x = 34;
    }
    when (33) {
     yield;
     die 'not reached 4';
     my $x = 35;
    }
    die 'not reached 5';
    my $x = 36;
   }
  }, 37)
TESTCASE
 is $@, '', 'yield() in for { } in given did not croak';
 is $loop, 33, 'yield() exited for on the second iteration';
 # A loop exited by last() evaluates to an empty list, but a loop that reached
 # its natural end evaluates to false!
 is_deeply \@res, [ 31, '', 37 ], 'yield() in when { }';
}
