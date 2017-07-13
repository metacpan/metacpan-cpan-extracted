package Number::MuPhone::Parser::FR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'FR'             );
has '+country_code'         => ( default => '33'             );
has '+country_name'         => ( default => 'France' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
