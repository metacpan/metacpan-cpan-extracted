use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Fatal;

use MooseX::Types -declare => ['Foo'];
use MooseX::Types::Moose qw( Any );

is(
    exception { subtype Foo, as Any },
    undef,
    'no exception when subtyping Any type'
);

done_testing();
