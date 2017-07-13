package Number::MuPhone::Parser::IM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IM'             );
has '+country_code'         => ( default => '44'             );
has '+country_name'         => ( default => 'Isle of Man' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
