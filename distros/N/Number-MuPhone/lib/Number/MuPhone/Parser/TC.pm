package Number::MuPhone::Parser::TC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TC'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Turks and Caicos Islands' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
