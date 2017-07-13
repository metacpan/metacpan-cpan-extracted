package Number::MuPhone::Parser::AX;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AX'             );
has '+country_code'         => ( default => '358'             );
has '+country_name'         => ( default => 'Aland Islands - Finland' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
