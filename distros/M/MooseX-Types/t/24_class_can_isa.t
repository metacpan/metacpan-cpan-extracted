use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

use MooseX::Types::TypeDecorator;

is(
    exception { MooseX::Types::TypeDecorator->isa('X') },
    undef,
    'no exception calling ->isa on MooseX::Types::TypeDecorator as class method'
);

is(
    exception { MooseX::Types::TypeDecorator->can('X') },
    undef,
    'no exception calling ->can on MooseX::Types::TypeDecorator as class method'
);

done_testing();
