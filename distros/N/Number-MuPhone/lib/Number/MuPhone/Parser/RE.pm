package Number::MuPhone::Parser::RE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'RE'             );
has '+country_code'         => ( default => '262'             );
has '+country_name'         => ( default => 'Reunion' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
