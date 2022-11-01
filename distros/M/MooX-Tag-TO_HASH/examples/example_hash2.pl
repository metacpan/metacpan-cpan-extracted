package My::Test::C4;

use Moo;
with 'MooX::Tag::TO_HASH';

has cow            => ( is => 'ro', to_hash => 1 );
has duck           => ( is => 'ro', to_hash => 'goose,if_exists', );
has horse          => ( is => 'ro', to_hash => ',if_defined', );
has hen            => ( is => 'ro', to_hash => 1, );
has secret_admirer => ( is => 'ro', );

# upper case the hash keys
sub modify_hashr {
    my ( $self, $hashr ) = @_;
    $hashr->{ uc $_ } = delete $hashr->{$_} for keys %$hashr;
};

# and elsewhere:
use Data::Dumper;

print Dumper(
    My::Test::C4->new(
        cow            => 'Daisy',
        hen            => 'Ruby',
        duck           => 'Donald',
        horse          => 'Ed',
        secret_admirer => 'Nemo'
    )->TO_HASH
);

