package Number::MuPhone::Parser::DJ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'DJ'             );
has '+country_code'         => ( default => '253'             );
has '+country_name'         => ( default => 'Djibouti' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
