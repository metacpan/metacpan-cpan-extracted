package Number::MuPhone::Parser::IR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IR'             );
has '+country_code'         => ( default => '98'             );
has '+country_name'         => ( default => 'Iran' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
