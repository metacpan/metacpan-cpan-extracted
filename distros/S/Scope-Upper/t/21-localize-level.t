#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<localize UP HERE>;

use Scope::Upper::TestGenerator;

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize '\$main::y' => 1 => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i) = @_;
 my $j = ($i == $height - $level) ? 1 : 'undef';
 return "verbose_is(\$main::y, $j, 'y h=$height, l=$level, i=$i');\n";
};

our ($x, $y, $testcase);

for my $level (0 .. 2) {
 for my $height ($level + 1 .. $level + 2) {
  my $tests = Scope::Upper::TestGenerator::gen($height, $level);
  for $testcase (@$tests) {
   $x = $y = undef;
   eval $testcase;
   diag $@ if $@;
  }
 }
}
