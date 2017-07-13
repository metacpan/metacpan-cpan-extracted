package Number::MuPhone::Parser::NA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NA'             );
has '+country_code'         => ( default => '264'             );
has '+country_name'         => ( default => 'Namibia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
