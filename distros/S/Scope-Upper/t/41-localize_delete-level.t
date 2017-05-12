#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<localize_delete UP HERE>;

use Scope::Upper::TestGenerator;

our ($x, $testcase);

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize_delete '\@main::a', 2 => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i) = @_;
 my $j = ($i == $height - $level) ? '1' : '1, undef, 2';
 return "is_deeply(\\\@main::a, [ $j ], 'a h=$height, l=$level, i=$i');\n";
};

our @a;

for my $level (0 .. 2) {
 for my $height ($level + 1 .. $level + 2) {
  my $tests = Scope::Upper::TestGenerator::gen($height, $level);
  for (@$tests) {
   $testcase = $_;
   $x = undef;
   @a = (1);
   $a[2] = 2;
   eval;
   diag $@ if $@;
  }
 }
}

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize_delete '%main::h', 'a' => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i) = @_;
 my $j = ($i == $height - $level) ? 'b => 2' : 'a => 1, b => 2';
 return "is_deeply(\\%main::h, { $j }, 'h h=$height, l=$level, i=$i');\n";
};

our %h;

for my $level (0 .. 2) {
 for my $height ($level + 1 .. $level + 2) {
  my $tests = Scope::Upper::TestGenerator::gen($height, $level);
  for (@$tests) {
   $testcase = $_;
   $x = undef;
   %h = (a => 1, b => 2);
   eval;
   diag $@ if $@;
  }
 }
}
