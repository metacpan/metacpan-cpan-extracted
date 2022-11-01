package My::Test::C4;

use Moo;
with 'MooX::Tag::TO_JSON';

has cow              => ( is => 'ro', to_json => 1 );
has duck             => ( is => 'ro', to_json => 'goose,if_exists', );
has horse            => ( is => 'ro', to_json => ',if_defined', );
has hen              => ( is => 'ro', to_json => 1, );
has barn_door_closed => ( is => 'ro', to_json => ',bool' );
has secret_admirer   => ( is => 'ro', );

# upper case the json keys
sub modify_jsonr {
    my ( $self, $jsonr ) = @_;
    $jsonr->{ uc $_ } = delete $jsonr->{$_} for keys %$jsonr;
};

# and elsewhere:
use Data::Dumper;

print Dumper(
    My::Test::C4->new(
        cow              => 'Daisy',
        hen              => 'Ruby',
        duck             => 'Donald',
        horse            => 'Ed',
        barn_door_closed => 1,
        secret_admirer   => 'Nemo'
    )->TO_JSON
);

