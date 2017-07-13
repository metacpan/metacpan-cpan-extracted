package Number::MuPhone::Parser::GF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GF'             );
has '+country_code'         => ( default => '594'             );
has '+country_name'         => ( default => 'French Guiana' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
