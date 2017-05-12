use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';

use MooseX::Types::Path::Tiny 'Path';
use Path::Tiny;

ok(is_Path(path('foo')), 'is_Path');

ok(Path->isa('Moose::Meta::TypeConstraint'), 'type is available as an import');

ok(MooseX::Types::Path::Tiny->can('Path'), 'type is available as a fully-qualified name');

done_testing;
