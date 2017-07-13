package Number::MuPhone::Parser::NP;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NP'             );
has '+country_code'         => ( default => '977'             );
has '+country_name'         => ( default => 'Nepal' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
