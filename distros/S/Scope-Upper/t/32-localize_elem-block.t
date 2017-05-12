#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<localize_elem UP HERE>;

use Scope::Upper::TestGenerator;

our $testcase;

local $Scope::Upper::TestGenerator::local_test = sub { '' };

local $Scope::Upper::TestGenerator::allblocks = 1;

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize_elem '\@a', 1 => 0 => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i, $x) = @_;
 my $j = ($i == $height - $level) ? 0 : (defined $x ? $x : 11);
 return "verbose_is(\$a[1], $j, 'x h=$height, l=$level, i=$i');\n";
};

local $Scope::Upper::TestGenerator::local_var = '$a[1]';

our @a;

for my $level (0 .. 1) {
 my $height = $level + 1;
 my $tests = Scope::Upper::TestGenerator::gen($height, $level);
 for $testcase (@$tests) {
  @a = (10, 11);
  eval $testcase;
  diag $@ if $@;
 }
}

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "localize_elem '%h', 'a' => 0 => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i, $x) = @_;
 my $j = ($i == $height - $level) ? 0 : (defined $x ? $x : 'undef');
 return "verbose_is(\$h{a}, $j, 'x h=$height, l=$level, i=$i');\n";
};

local $Scope::Upper::TestGenerator::local_var = '$h{a}';

our %h;

for my $level (0 .. 1) {
 my $height = $level + 1;
 my $tests = Scope::Upper::TestGenerator::gen($height, $level);
 for $testcase (@$tests) {
  %h = ();
  eval $testcase;
  diag $@ if $@;
 }
}
