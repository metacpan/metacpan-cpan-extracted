package Number::MuPhone::Parser::NL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NL'             );
has '+country_code'         => ( default => '31'             );
has '+country_name'         => ( default => 'Netherlands' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
