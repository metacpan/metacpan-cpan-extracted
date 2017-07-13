package Number::MuPhone::Parser::GS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GS'             );
has '+country_code'         => ( default => '500'             );
has '+country_name'         => ( default => 'South Georgia and the South Sandwich Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
