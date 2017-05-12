use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Deep::Type;
use MooseX::Types::Moose 'Str';

cmp_deeply(
    {
        message => 'ack I am slain',
        counter => 123,
    },
    {
        message => is_type(Str),
        counter => is_type(sub { die "not an integer" unless int($_[0]) eq $_[0] }),
    },
    'message is a plain string, counter is a number',
);

done_testing;
