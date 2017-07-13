package Number::MuPhone::Parser::MC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MC'             );
has '+country_code'         => ( default => '377'             );
has '+country_name'         => ( default => 'Monaco' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
