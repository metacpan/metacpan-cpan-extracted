package Number::MuPhone::Parser::CD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CD'             );
has '+country_code'         => ( default => '243'             );
has '+country_name'         => ( default => 'Congo (Dem. Rep. of / Zaire)' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
