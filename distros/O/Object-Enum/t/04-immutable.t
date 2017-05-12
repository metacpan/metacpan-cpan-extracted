#!perl

use strict;
use warnings;
use Scalar::Util 'refaddr';
use Test::More;

use_ok 'Object::Enum';

my $a = Object::Enum->readonly([qw[red green blue]],'green');

ok $a->is_green;
ok !$a->is_red;
ok !$a->is_blue;
ok $a->can('set_red');
ok $a->value('red'), 'attempt to set value';
ok $a->is_green, 'value persists';

my $b = $a->clone;

ok refaddr($a) != refaddr($b);
ok !$b->_readonly, 'cloned is not read-only';
ok $b->is_green, 'is green';
ok $b->can('set_red'), 'cloned object has setters';
ok $b->set_red;
ok $b->is_red;

done_testing();
