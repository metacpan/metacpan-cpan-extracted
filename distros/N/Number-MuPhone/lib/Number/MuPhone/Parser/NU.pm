package Number::MuPhone::Parser::NU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NU'             );
has '+country_code'         => ( default => '683'             );
has '+country_name'         => ( default => 'Niue' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
