#!perl -T

use strict;
use warnings;

use lib 't/lib';
use Test::Leaner 'no_plan';

use Scope::Upper qw<reap UP HERE>;

use Scope::Upper::TestGenerator;

local $Scope::Upper::TestGenerator::call = sub {
 my ($height, $level, $i) = @_;
 $level = $level ? 'UP ' x $level : 'HERE';
 return [ "reap \\&check => $level;\n" ];
};

local $Scope::Upper::TestGenerator::test = sub {
 my ($height, $level, $i, $x) = @_;
 my $j = $i < $height - $level ? 0 : (defined $x ? $x : 'undef');
 return "verbose_is(\$x, $j, 'x h=$height, l=$level, i=$i');\n";
};

local $Scope::Upper::TestGenerator::local_decl = sub {
 my ($height, $level, $i, $x) = @_;
 return $i == $height - $level ? "\$x = $x;\n" : "local \$x = $x;\n";
};

local $Scope::Upper::TestGenerator::local_test = sub { '' };

local $Scope::Upper::TestGenerator::allblocks = 1;

our ($x, $testcase);

sub check { $x = (defined $x) ? ($x ? 0 : $x . 'x') : 0 }

for my $level (0 .. 1) {
 my $height = $level + 1;
 my $tests = Scope::Upper::TestGenerator::gen($height, $level);
 for $testcase (@$tests) {
  $x = undef;
  eval $testcase;
  diag $@ if $@;
 }
}
