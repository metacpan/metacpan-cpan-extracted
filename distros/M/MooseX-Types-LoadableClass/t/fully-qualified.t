use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::LoadableClass 'LoadableClass';

use lib 't/lib';

ok(is_LoadableClass('FooBarTestClass'), 'is_LoadableClass');

ok(LoadableClass->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::LoadableClass::LoadableClass->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;
