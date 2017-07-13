package Number::MuPhone::Parser::AL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AL'             );
has '+country_code'         => ( default => '355'             );
has '+country_name'         => ( default => 'Albania' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
