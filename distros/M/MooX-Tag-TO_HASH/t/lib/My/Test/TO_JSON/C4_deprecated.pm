package My::Test::TO_JSON::C4_deprecated;

use Moo;
with 'MooX::Tag::TO_JSON';

has c4_bool => ( is => 'ro', to_json => ',bool', default => 42 );
has c4_str  => ( is => 'ro', to_json => ',str',  default => 43 );
has c4_num  => ( is => 'ro', to_json => ',num',  default => '44' );


has cow            => ( is => 'ro', to_json => 1 );
has duck           => ( is => 'ro', to_json => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_json => ',omit_if_empty', );
has hen            => ( is => 'ro', to_json => 1, );
has secret_admirer => ( is => 'ro', );

around TO_JSON => sub {
    my ( $orig, $obj ) = @_;
    my $hash = $obj->$orig;
    $hash->{$_} = uc $hash->{$_} for grep defined $hash->{$_}, keys %$hash;
    return $hash;
};

1;

