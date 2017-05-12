#!perl -T

use 5.006;
use strict;
use warnings;
use warnings FATAL => 'all';
use Data::Dumper;
use Test::More;

plan tests => 1;

use lib 'lib';
use Parse::Gnaw;


# A Simple Rule Example
rule( 'rule1', 'H', 'I' );

print Dumper $rule1;

ok($rule1->[0]->[1] eq 'rule1', "check rulename is packed into rule");
