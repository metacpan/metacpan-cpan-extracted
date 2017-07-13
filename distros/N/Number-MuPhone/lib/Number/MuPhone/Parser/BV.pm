package Number::MuPhone::Parser::BV;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BV'             );
has '+country_code'         => ( default => '47'             );
has '+country_name'         => ( default => 'Bouvet Island - Norway' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
