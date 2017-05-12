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
use Parse::Gnaw::LinkedList;


predeclare('rule1');
rule( 'rule2', 'c', call('rule1') );
rule( 'rule1', 'a', 'b');

#print Dumper $rule1;

ok($rule1->[0]->[1] eq 'rule1', "check rulename is packed into rule");

