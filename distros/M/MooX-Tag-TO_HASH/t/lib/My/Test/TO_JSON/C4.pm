package My::Test::TO_JSON::C4;

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

sub modify_jsonr {
    my ( $self, $jsonr ) = @_;
    $jsonr->{$_} = uc $jsonr->{$_}
      for grep defined $jsonr->{$_}, keys %$jsonr;
};

1;

