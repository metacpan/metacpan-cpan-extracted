package Number::MuPhone::Parser::FI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'FI'             );
has '+country_code'         => ( default => '358'             );
has '+country_name'         => ( default => 'Finland' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
