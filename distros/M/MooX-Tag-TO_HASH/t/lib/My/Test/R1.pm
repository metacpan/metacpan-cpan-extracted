package My::Test::R1;

use Moo::Role;

with 'MooX::Tag::TO_HASH';

has donkey => ( is => 'ro', to_hash => ',omit_if_empty' );

1;

