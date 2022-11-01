package My::Test::TO_JSON::C1_R1;

use Moo;

with 'My::Test::TO_JSON::R1';

has c1_r1_bool     => ( is => 'ro', to_json => ',bool', default => 62 );
has c1_r1_str      => ( is => 'ro', to_json => ',str',  default => 63 );
has c1_r1_num      => ( is => 'ro', to_json => ',num',  default => '64' );
has cow            => ( is => 'ro', to_json => 1 );
has duck           => ( is => 'ro', to_json => 'goose,omit_if_empty', );
has horse          => ( is => 'ro', to_json => ',omit_if_empty', );
has hen            => ( is => 'ro', to_json => 1, );
has secret_admirer => ( is => 'ro', );

1;

