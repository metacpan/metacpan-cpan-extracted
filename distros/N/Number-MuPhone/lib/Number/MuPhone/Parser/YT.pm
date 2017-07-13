package Number::MuPhone::Parser::YT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'YT'             );
has '+country_code'         => ( default => '262'             );
has '+country_name'         => ( default => 'Mayotte' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
