package Number::MuPhone::Parser::SX;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SX'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Sint Maarten' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
