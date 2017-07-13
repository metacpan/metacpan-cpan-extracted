package Number::MuPhone::Parser::BE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BE'             );
has '+country_code'         => ( default => '32'             );
has '+country_name'         => ( default => 'Belgium' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
