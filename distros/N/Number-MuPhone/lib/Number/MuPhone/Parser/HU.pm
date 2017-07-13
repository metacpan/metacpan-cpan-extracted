package Number::MuPhone::Parser::HU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'HU'             );
has '+country_code'         => ( default => '36'             );
has '+country_name'         => ( default => 'Hungary' );
has '+_national_dial_prefix'      => ( default => '06' );
has '+_international_dial_prefix' => ( default => '00' );

1;
