package Number::MuPhone::Parser::BS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BS'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Bahamas' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
