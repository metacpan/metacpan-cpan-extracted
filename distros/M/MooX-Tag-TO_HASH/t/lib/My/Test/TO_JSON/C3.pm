package My::Test::TO_JSON::C3;

use Moo;
with 'MooX::Tag::TO_JSON';

has c3_bool => ( is => 'ro', to_json => ',bool', default => 32 );
has c3_str  => ( is => 'ro', to_json => ',str',  default => 33 );
has c3_num  => ( is => 'ro', to_json => ',num',  default => '34' );

has cow            => ( is => 'ro', to_json => 1 );
has duck           => ( is => 'ro', to_json => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_json => ',omit_if_empty', );
has hen            => ( is => 'ro', to_json => 1, );
has secret_admirer => ( is => 'ro', );

1;

