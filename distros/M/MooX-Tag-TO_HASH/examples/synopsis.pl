package My::Farm;

use Moo;
with 'MooX::Tag::TO_HASH';

has cow            => ( is => 'ro', to_hash => 1 );
has duck           => ( is => 'ro', to_hash => 'goose,if_exists', );
has horse          => ( is => 'ro', to_hash => ',if_defined', );
has hen            => ( is => 'ro', to_hash => 1, );
has secret_admirer => ( is => 'ro', );

# and somewhere else...

use Data::Dumper;
my $farm = My::Farm->new(
    cow            => 'Daisy',
    duck           => 'Frank',
    secret_admirer => 'Fluffy',
);

print Dumper $farm->TO_HASH;
