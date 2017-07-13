package Number::MuPhone::Parser::TK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TK'             );
has '+country_code'         => ( default => '690'             );
has '+country_name'         => ( default => 'Tokelau' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
