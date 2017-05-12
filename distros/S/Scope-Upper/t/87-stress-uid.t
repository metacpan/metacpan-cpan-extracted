#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<uplevel uid validate_uid CALLER>;

my $max_level = 10;

our $inner_uplevels;

sub rec {
 my $n      = shift;
 my $level  = shift;
 my $target = shift;
 my @uids   = @_;

 if ($n > 0) {
  my @args = ($n - 1 => ($level, $target) => @uids);
  if ($inner_uplevels) {
   return uplevel {
    rec(@args, uid());
   };
  } else {
   return rec(@args, uid());
  }
 }

 my $desc = "level=$level, target=$target, inner_uplevels=$inner_uplevels";

 uplevel {
  for my $i (1 .. $target) {
   my $j = $level - $i;
   ok !validate_uid($uids[$j]), "UID $j is invalid for $desc";
  }
  for my $i ($target + 1 .. $level) {
   my $j = $level - $i;
   ok validate_uid($uids[$j]), "UID $j is valid for $desc";
  }
 } CALLER($target);
}

{
 local $inner_uplevels = 0;
 for my $level (1 .. $max_level) {
  for my $target (1 .. $level) {
   rec($level => ($level, $target));
  }
 }
}

{
 local $inner_uplevels = 1;
 for my $level (1 .. $max_level) {
  for my $target (1 .. $level) {
   rec($level => ($level, $target));
  }
 }
}
