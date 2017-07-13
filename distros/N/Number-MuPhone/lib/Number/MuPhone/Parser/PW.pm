package Number::MuPhone::Parser::PW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PW'             );
has '+country_code'         => ( default => '680'             );
has '+country_name'         => ( default => 'Palau' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '011' );

1;
