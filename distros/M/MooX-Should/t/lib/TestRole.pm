package TestRole;

use Moo::Role;
use MooX::Should;

use Types::Standard qw/ Int /;

use namespace::autoclean;

has c => (
    is     => 'ro',
    should => Int,
);

1;
