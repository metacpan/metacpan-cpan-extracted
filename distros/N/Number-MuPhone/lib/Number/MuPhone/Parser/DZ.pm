package Number::MuPhone::Parser::DZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'DZ'             );
has '+country_code'         => ( default => '213'             );
has '+country_name'         => ( default => 'Algeria' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
