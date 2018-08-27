package TestClass;

use Moo;
use MooX::Should;

use Types::Common::Numeric qw/ PositiveNum /;
use Types::Standard qw/ Int /;

use namespace::autoclean;

has a => (
    is     => 'ro',
    should => PositiveNum,
    isa    => Int,
);

has b => (
    is     => 'ro',
    should => Int,
);

1;
