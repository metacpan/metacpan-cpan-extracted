package My::Test::TO_JSON::C1;

use Moo;
with 'MooX::Tag::TO_JSON';

has c1_bool        => ( is => 'ro', to_json => ',bool', default => 12 );
has c1_str         => ( is => 'ro', to_json => ',str',  default => 13 );
has c1_num         => ( is => 'ro', to_json => ',num',  default => '14' );
has cow            => ( is => 'ro', to_json => 1 );
has duck           => ( is => 'ro', to_json => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_json => ',if_exists', );
has hen            => ( is => 'ro', to_json => 1, );
has porcupine      => ( is => 'ro', to_json => ',if_defined', );
has secret_admirer => ( is => 'ro', );

1;

