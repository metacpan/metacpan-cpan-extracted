package Number::MuPhone::Parser::TD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TD'             );
has '+country_code'         => ( default => '235'             );
has '+country_name'         => ( default => 'Chad' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
