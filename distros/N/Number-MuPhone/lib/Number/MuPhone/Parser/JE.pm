package Number::MuPhone::Parser::JE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'JE'             );
has '+country_code'         => ( default => '44'             );
has '+country_name'         => ( default => 'Jersey' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
