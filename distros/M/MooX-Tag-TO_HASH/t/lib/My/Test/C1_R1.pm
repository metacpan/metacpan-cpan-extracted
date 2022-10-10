package My::Test::C1_R1;

use Moo;

with 'My::Test::R1';

has cow            => ( is => 'ro', to_hash => 1 );
has duck           => ( is => 'ro', to_hash => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_hash => ',omit_if_empty', );
has hen            => ( is => 'ro', to_hash => 1, );
has secret_admirer => ( is => 'ro', );

1;

