use strict;
use warnings;

use lib 't/lib';

use Test::More 0.88;
use Class::Load 'is_class_loaded';
use MooseX::Types::LoadableClass qw(LoadableClass LoadableRole);

ok !is_class_loaded('FooBarTestClass');
ok LoadableClass->check('FooBarTestClass');
ok is_class_loaded('FooBarTestClass');
ok(is_LoadableClass('FooBarTestClass'), 'is_LoadableClass');
use namespace::clean 0.19 -except => [qw/ import /];

ok !LoadableClass->check('FooBarTestClassDoesNotExist');
ok(!is_LoadableClass('FooBarTestClassDoesNotExist'));

ok !is_class_loaded('FooBarTestRole');
ok LoadableRole->check('FooBarTestRole');
ok is_class_loaded('FooBarTestRole');

ok !LoadableRole->check('FooBarTestClass');

ok !LoadableRole->check('FooBarTestRoleDoesNotExist');

done_testing;
