#!perl -T

use strict;
use warnings;

use Test::More tests => 2 * 7;

require Scalar::Vec::Util;

my %syms = (
 vfill    => '$$$$',
 vcopy    => '$$$$$',
 veq      => '$$$$$',
 vshift   => '$$$$;$',
 vrot     => '$$$$',
 SVU_PP   => '',
 SVU_SIZE => '',
);

for (keys %syms) {
 eval { Scalar::Vec::Util->import($_) };
 is $@,            '',        "import $_";
 is prototype($_), $syms{$_}, "prototype $_";
}
