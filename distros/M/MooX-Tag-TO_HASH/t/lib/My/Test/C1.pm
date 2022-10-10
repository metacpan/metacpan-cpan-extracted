package My::Test::C1;

use Moo;
with 'MooX::Tag::TO_HASH';

has cow            => ( is => 'ro', to_hash => 1 );
has duck           => ( is => 'ro', to_hash => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_hash => ',if_exists', );
has hen            => ( is => 'ro', to_hash => 1, );
has porcupine      => ( is => 'ro', to_hash => ',if_defined', );
has secret_admirer => ( is => 'ro', );

1;

