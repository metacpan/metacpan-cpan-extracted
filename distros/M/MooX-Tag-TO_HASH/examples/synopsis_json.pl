package My::Farm;

use Moo;
with 'MooX::Tag::TO_JSON';

has cow              => ( is => 'ro', to_json => 1 );
has duck             => ( is => 'ro', to_json => 'goose,if_exists', );
has horse            => ( is => 'ro', to_json => ',if_defined', );
has hen              => ( is => 'ro', to_json => 1, );
has barn_door_closed => ( is => 'ro', to_json => ',bool' );
has secret_admirer   => ( is => 'ro', );

# and somewhere else...

use Data::Dumper;
my $farm = My::Farm->new(
    cow              => 'Daisy',
    duck             => 'Frank',
    barn_door_closed => 0,
    secret_admirer   => 'Fluffy',
);

print Dumper $farm->TO_JSON;
