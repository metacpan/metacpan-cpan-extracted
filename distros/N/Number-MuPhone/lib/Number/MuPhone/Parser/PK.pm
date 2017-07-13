package Number::MuPhone::Parser::PK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PK'             );
has '+country_code'         => ( default => '92'             );
has '+country_name'         => ( default => 'Pakistan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
