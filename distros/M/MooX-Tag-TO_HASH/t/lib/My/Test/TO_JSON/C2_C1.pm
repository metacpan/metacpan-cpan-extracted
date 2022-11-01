package My::Test::TO_JSON::C2_C1;

use Moo;

extends 'My::Test::TO_JSON::C1';

with 'MooX::Tag::TO_JSON';

has c2_bool => ( is => 'ro', to_json => ',bool', default => 22 );
has c2_str  => ( is => 'ro', to_json => ',str',  default => 23 );
has c2_num  => ( is => 'ro', to_json => ',num',  default => '24' );

has pig => ( is => 'ro', to_json => 1 );

1;

