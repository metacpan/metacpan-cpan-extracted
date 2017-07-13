package Number::MuPhone::Parser::KH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KH'             );
has '+country_code'         => ( default => '855'             );
has '+country_name'         => ( default => 'Cambodia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '001' );

1;
