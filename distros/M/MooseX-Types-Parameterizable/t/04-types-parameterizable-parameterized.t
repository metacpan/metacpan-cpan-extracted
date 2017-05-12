use strict;
use warnings;

use Test::More;
use MooseX::Types::Parameterizable qw(Parameterizable);
use MooseX::Types::Moose qw( Int ArrayRef );
use MooseX::Types -declare=>[qw( EvenInt ArrayOfEvenIntsWithLength )];

ok subtype( EvenInt,
    as Int,
    where {
        my $val = shift @_;
        return $val % 2 ? 0:1;
    }),
  'Created a subtype of Int';

ok subtype(
    ArrayOfEvenIntsWithLength,
    as Parameterizable[
        ArrayRef[EvenInt],
        Int,
    ],
    where {
        my ($value, $int) = @_;
        my $length = scalar(@$value);
        $length < ($int+1) ? 1:0;
    },
), 'Created parameterized parameterized!';

ok ! ArrayOfEvenIntsWithLength([5])->check([2,4,6,8,10,12,14]),
 'correctly failed too long array';

ok ! ArrayOfEvenIntsWithLength([5])->check([2,4,6,8,11]),
 'correctly failed with odd number in array';

ok ArrayOfEvenIntsWithLength([5])->check([2,4,6]),
 'correctly passed array';

done_testing;

