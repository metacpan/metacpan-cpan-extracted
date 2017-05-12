use strict;
use warnings;

use Test::More;
use MooseX::Types -declare=>[qw( SizedArray )];
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw( Int ArrayRef );

ok subtype(
    SizedArray,
    as Parameterizable[ArrayRef,Int],
    where {
        my ($value, $max) = @_;
        @$value > $max
    },
    message {
        my($value, $max) = @_;
        return sprintf('%d > %d', scalar(@$value), $max);
    }
), 'Created parameterized type';

is SizedArray([3])->get_message([1..4]), q{4 > 3}, 'custom message';

done_testing;
