package Number::MuPhone::Parser::AE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AE'             );
has '+country_code'         => ( default => '971'             );
has '+country_name'         => ( default => 'United Arab Emirates' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
