use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use MooseX::Types::ISO8601 'ISO8601DateStr';

ok(is_ISO8601DateStr('2014-01-01'), 'is_ISO8601DateStr');

ok(ISO8601DateStr->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::ISO8601::ISO8601DateStr->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;
