#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<localize_elem UP HERE>;

use Scope::Upper::TestGenerator;

our ($x, $testcase);

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize_elem '\@main::a', 1 => 3 => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i) = @_;
 my $j = ($i == $height - $level) ? '1, 3' : '1, 2';
 return "is_deeply(\\\@main::a, [ $j ], 'a h=$height, l=$level, i=$i');\n";
};

our @a;

for my $level (0 .. 2) {
 for my $height ($level + 1 .. $level + 2) {
  my $tests = Scope::Upper::TestGenerator::gen($height, $level);
  for $testcase (@$tests) {
   $x = undef;
   @a = (1, 2);
   eval $testcase;
   diag $@ if $@;
  }
 }
}

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize_elem '%main::h', 'a' => 1 => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i) = @_;
 my $j = ($i == $height - $level) ? 'a => 1' : '';
 return "is_deeply(\\%main::h, { $j }, 'h h=$height, l=$level, i=$i');\n";
};

our %h;

for my $level (0 .. 2) {
 for my $height ($level + 1 .. $level + 2) {
  my $tests = Scope::Upper::TestGenerator::gen($height, $level);
  for $testcase (@$tests) {
   $x = undef;
   %h = ();
   eval $testcase;
   diag $@ if $@;
  }
 }
}
