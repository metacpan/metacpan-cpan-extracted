package Number::MuPhone::Parser::AD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AD'             );
has '+country_code'         => ( default => '376'             );
has '+country_name'         => ( default => 'Andorra' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
