package Number::MuPhone::Parser::CA;
use Moo;

extends 'Number::MuPhone::Parser::US';

# Canada

has '+country_name' => ( default => 'Canada' );
has '+country'      => ( default => 'CA' );

1;
