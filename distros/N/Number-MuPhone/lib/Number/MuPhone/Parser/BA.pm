package Number::MuPhone::Parser::BA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BA'             );
has '+country_code'         => ( default => '387'             );
has '+country_name'         => ( default => 'Bosnia and Herzegovina' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
