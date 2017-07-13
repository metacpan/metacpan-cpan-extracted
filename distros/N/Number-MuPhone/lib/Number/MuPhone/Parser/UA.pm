package Number::MuPhone::Parser::UA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'UA'             );
has '+country_code'         => ( default => '380'             );
has '+country_name'         => ( default => 'Ukraine' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
