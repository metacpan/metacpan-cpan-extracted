package Number::MuPhone::Parser::VE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VE'             );
has '+country_code'         => ( default => '58'             );
has '+country_name'         => ( default => 'Venezuela' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
