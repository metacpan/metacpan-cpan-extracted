package My::Test::C4;

use Moo;
with 'MooX::Tag::TO_HASH';

has cow            => ( is => 'ro', to_hash => 1 );
has duck           => ( is => 'ro', to_hash => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_hash => ',omit_if_empty', );
has hen            => ( is => 'ro', to_hash => 1, );
has secret_admirer => ( is => 'ro', );

around TO_HASH => sub {
    my ( $orig, $obj ) = @_;
    my $hash = $obj->$orig;
    $hash->{$_} = uc $hash->{$_} for grep defined $hash->{$_}, keys %$hash;
    return $hash;
};

1;

