package Number::MuPhone::Parser::CU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CU'             );
has '+country_code'         => ( default => '53'             );
has '+country_name'         => ( default => 'Cuba' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '119' );

1;
