#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 3;

require Sub::Prototype::Util;

my %syms = (
 flatten => undef,
 recall  => undef,
 wrap    => undef,
);

for (keys %syms) {
 eval { Scope::Upper->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
