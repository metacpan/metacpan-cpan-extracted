package Number::MuPhone::Parser::CX;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CX'             );
has '+country_code'         => ( default => '61'             );
has '+country_name'         => ( default => 'Christmas Island' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '0011' );

1;
