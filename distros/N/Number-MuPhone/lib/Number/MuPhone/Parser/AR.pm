package Number::MuPhone::Parser::AR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AR'             );
has '+country_code'         => ( default => '54'             );
has '+country_name'         => ( default => 'Argentina' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
