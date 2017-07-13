package Number::MuPhone::Parser::PM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PM'             );
has '+country_code'         => ( default => '508'             );
has '+country_name'         => ( default => 'Saint Pierre and Miquelon' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
