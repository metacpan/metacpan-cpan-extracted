package My::Test::C2_C1_R1;

use Moo;

extends 'My::Test::C1';

with 'MooX::Tag::TO_HASH';
with 'My::Test::R1';

has pig => ( is => 'ro', to_hash => 1 );

1;

