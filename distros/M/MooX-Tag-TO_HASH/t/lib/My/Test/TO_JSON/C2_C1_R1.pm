package My::Test::TO_JSON::C2_C1_R1;

use Moo;

extends 'My::Test::TO_JSON::C1';

with 'MooX::Tag::TO_JSON';
with 'My::Test::TO_JSON::R1';

has c2_c1_r1_bool => ( is => 'ro', to_json => ',bool', default => 82 );
has c2_c1_r1_str  => ( is => 'ro', to_json => ',str',  default => 83 );
has c2_c1_r1_num  => ( is => 'ro', to_json => ',num',  default => '84' );
has pig           => ( is => 'ro', to_json => 1 );

1;

