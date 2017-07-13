package Number::MuPhone::Parser::AZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AZ'             );
has '+country_code'         => ( default => '994'             );
has '+country_name'         => ( default => 'Azerbaijan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
