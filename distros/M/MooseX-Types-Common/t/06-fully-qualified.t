use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Common::String 'SimpleStr';

ok(is_SimpleStr('a string'), 'is_SimpleStr');

ok(SimpleStr->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::Common::String::SimpleStr->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;
