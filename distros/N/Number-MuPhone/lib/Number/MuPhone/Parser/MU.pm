package Number::MuPhone::Parser::MU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MU'             );
has '+country_code'         => ( default => '230'             );
has '+country_name'         => ( default => 'Mauritius' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
