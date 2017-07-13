package Number::MuPhone::Parser::LB;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LB'             );
has '+country_code'         => ( default => '961'             );
has '+country_name'         => ( default => 'Lebanon' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
