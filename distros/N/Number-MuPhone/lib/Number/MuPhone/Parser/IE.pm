package Number::MuPhone::Parser::IE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IE'             );
has '+country_code'         => ( default => '353'             );
has '+country_name'         => ( default => 'Ireland' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
