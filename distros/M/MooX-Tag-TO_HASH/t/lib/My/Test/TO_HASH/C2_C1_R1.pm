package My::Test::TO_HASH::C2_C1_R1;

use Moo;

extends 'My::Test::TO_HASH::C1';

with 'MooX::Tag::TO_HASH';
with 'My::Test::TO_HASH::R1';

has pig => ( is => 'ro', to_hash => 1 );

1;

