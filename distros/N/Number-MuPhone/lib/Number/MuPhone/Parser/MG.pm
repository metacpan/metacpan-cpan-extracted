package Number::MuPhone::Parser::MG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MG'             );
has '+country_code'         => ( default => '261'             );
has '+country_name'         => ( default => 'Madagascar' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
