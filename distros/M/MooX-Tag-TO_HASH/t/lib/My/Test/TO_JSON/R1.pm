package My::Test::TO_JSON::R1;

use Moo::Role;

with 'MooX::Tag::TO_JSON';

has r1_bool => ( is => 'ro', to_json => ',bool', default => 52 );
has r1_str  => ( is => 'ro', to_json => ',str',  default => 53 );
has r1_num  => ( is => 'ro', to_json => ',num',  default => '54' );

has donkey => ( is => 'ro', to_json => ',omit_if_empty' );

1;

