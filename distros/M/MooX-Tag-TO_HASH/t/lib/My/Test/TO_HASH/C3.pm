package My::Test::TO_HASH::C3;

use Moo;
with 'MooX::Tag::TO_HASH';

has cow            => ( is => 'ro', to_hash => 1 );
has duck           => ( is => 'ro', to_hash => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_hash => ',omit_if_empty,no_recurse', );
has hen            => ( is => 'ro', to_hash => 1, );
has secret_admirer => ( is => 'ro', );

1;

