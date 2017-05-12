#!perl -T

use strict;
use warnings;

my ($tests, $reports, $subtests);
BEGIN {
 $tests    = 28;
 $reports  = 43;
 $subtests = 3;
}

use Test::More tests => $tests + $subtests * $reports;

use Perl::Critic::TestUtils qw<pcritique_with_violations>;

Perl::Critic::TestUtils::block_perlcriticrc();

my $policy = 'Dynamic::NoIndirect';

sub expect {
 my ($meth, $obj) = @_;
 $obj = ($obj =~ /^\s*\{/) ? "a block" : "object \"\Q$obj\E\"";
 qr/^Indirect call of method \"\Q$meth\E\" on $obj/,
}

sub zap (&) { }

TEST:
{
 local $/ = "####";

 my $id = 1;

 while (<DATA>) {
  s/^\s+//s;

  my ($code, $expected) = split /^-{4,}$/m, $_, 2;
  my @expected;
  {
   local $@;
   @expected = eval $expected;
   if ($@) {
    diag "Compilation of expected code $id failed: $@";
    next TEST;
   }
  }

  my @violations;
  {
   local $@;
   @violations = eval { pcritique_with_violations($policy, \$code) };
   if ($@) {
    diag "Critique test $id failed: $@";
    next TEST;
   }
  }

  is @violations, @expected, "right count of violations $id";

  for my $v (@violations) {
   my $exp = shift @expected;

   unless ($exp) {
    fail "Unexpected violation for chunk $id: " . $v->description;
    next TEST;
   }

   my $pos = $v->location;
   my ($meth, $obj, $line, $col) = @$exp;

   like $v->description, expect($meth, $obj), "description $id";
   is   $pos->[0], $line, "line $id";
   is   $pos->[1], $col,  "column $id";
  }

  ++$id;
 }
}

__DATA__
my $x = new X;
----
[ 'new', 'X', 1, 9 ]
####
use indirect; my $x = new X;
----
####
my $x = new X; $x = new X;
----
[ 'new', 'X', 1, 9 ], [ 'new', 'X', 1, 21 ]
####
my $x = new X    new X;
----
[ 'new', 'X', 1, 9 ], [ 'new', 'X', 1, 18 ]
####
my $x = new X    new Y;
----
[ 'new', 'X', 1, 9 ], [ 'new', 'Y', 1, 18 ]
####
my $x = new X;
my $y = new X;
----
[ 'new', 'X', 1, 9 ], [ 'new', 'X', 2, 9 ]
####
my $x = new
            X;
----
[ 'new', 'X', 1, 9 ]
####
my $x = new
 X new
    X;
----
[ 'new', 'X', 1, 9 ], [ 'new', 'X', 2, 4 ]
####
my $x = new new;
----
[ 'new', 'new', 1, 9 ]
####
our $obj;
use indirect; my $x = new $obj;
----
####
our $obj;
my $x = new $obj;
----
[ 'new', '$obj', 2, 9 ]
####
our $obj;
my $x = new $obj; $x = new $obj;
----
[ 'new', '$obj', 2, 9 ], [ 'new', '$obj', 2, 24 ]
####
our $obj;
my $x = new $obj    new $obj;
----
[ 'new', '$obj', 2, 9 ], [ 'new', '$obj', 2, 21 ]
####
our ($o1, $o2);
my $x = new $o1     new $o2;
----
[ 'new', '$o1', 2, 9 ], [ 'new', '$o2', 2, 21 ]
####
our $obj;
my $x = new $obj;
my $y = new $obj;
----
[ 'new', '$obj', 2, 9 ], [ 'new', '$obj', 3, 9 ]
####
our $obj;
my $x = new
            $obj;
----
[ 'new', '$obj', 2, 9 ]
####
our $obj;
my $x = new
 $obj new
    $obj;
----
[ 'new', '$obj', 2, 9 ], [ 'new', '$obj', 3, 7 ]
####
my $x = main::zap { };
----
####
my $x = meh { };
----
[ 'meh', '{', 1, 9 ]
####
my $x = meh {
 1
};
----
[ 'meh', '{', 1, 9 ]
####
my $x =
 meh { 1; 1
 };
----
[ 'meh', '{', 2, 2 ]
####
my $x = meh {
 new X;
};
----
[ 'meh', '{', 1, 9 ], [ 'new', 'X', 2, 2 ]
####
our $obj;
my $x = meh {
 new $obj;
}
----
[ 'meh', '{', 2, 9 ], [ 'new', '$obj', 3, 2 ]
####
my $x = meh { } new
                X;
----
[ 'meh', '{', 1, 9 ], [ 'new', 'X', 1, 17 ]
####
our $obj;
my $x = meh { } new
                $obj;
----
[ 'meh', '{', 2, 9 ], [ 'new', '$obj', 2, 17 ]
####
our $obj;
my $x = meh { new X } new $obj;
----
[ 'meh', '{', 2, 9 ], [ 'new', 'X', 2, 15 ], [ 'new', '$obj', 2, 23 ]
####
our $obj;
my $x = meh { new $obj } new X;
----
[ 'meh', '{', 2, 9 ], [ 'new', '$obj', 2, 15 ], [ 'new', 'X', 2, 26 ]
####
my $x = $invalid_global_when_strict_is_on; new X;
----
[ 'new', 'X', 1, 44 ]
