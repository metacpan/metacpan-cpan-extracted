package Number::MuPhone::Parser::SD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SD'             );
has '+country_code'         => ( default => '249'             );
has '+country_name'         => ( default => 'Sudan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
