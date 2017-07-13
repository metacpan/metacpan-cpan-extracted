package Number::MuPhone::Parser::NC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NC'             );
has '+country_code'         => ( default => '687'             );
has '+country_name'         => ( default => 'New Caledonia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
