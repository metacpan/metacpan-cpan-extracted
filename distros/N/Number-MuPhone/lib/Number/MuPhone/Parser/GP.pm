package Number::MuPhone::Parser::GP;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GP'             );
has '+country_code'         => ( default => '590'             );
has '+country_name'         => ( default => 'Guadeloupe' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
