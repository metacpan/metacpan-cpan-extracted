package My::Test::TO_HASH::C2_C1;

use Moo;

extends 'My::Test::TO_HASH::C1';

with 'MooX::Tag::TO_HASH';

has pig => ( is => 'ro', to_hash => 1 );

1;

