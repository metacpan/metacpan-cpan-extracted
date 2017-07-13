package Number::MuPhone::Parser::BR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BR'             );
has '+country_code'         => ( default => '55'             );
has '+country_name'         => ( default => 'Brazil' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
