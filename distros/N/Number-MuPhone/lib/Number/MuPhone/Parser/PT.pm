package Number::MuPhone::Parser::PT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PT'             );
has '+country_code'         => ( default => '351'             );
has '+country_name'         => ( default => 'Portugal' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
