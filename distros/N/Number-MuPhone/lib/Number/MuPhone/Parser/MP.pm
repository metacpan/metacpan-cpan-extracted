package Number::MuPhone::Parser::MP;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MP'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Northern Mariana Islands' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
