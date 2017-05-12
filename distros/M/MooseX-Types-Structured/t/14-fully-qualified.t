use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Moose 'Str';
use MooseX::Types::Structured 'Dict';

ok(Dict->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::Structured::Dict->isa('Moose::Meta::TypeConstraint'), 'type is available as a fully-qualified name');

done_testing;
