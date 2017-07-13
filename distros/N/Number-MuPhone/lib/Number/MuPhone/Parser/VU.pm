package Number::MuPhone::Parser::VU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VU'             );
has '+country_code'         => ( default => '678'             );
has '+country_name'         => ( default => 'Vanuatu' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
