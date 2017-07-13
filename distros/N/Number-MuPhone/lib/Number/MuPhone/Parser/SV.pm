package Number::MuPhone::Parser::SV;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SV'             );
has '+country_code'         => ( default => '503'             );
has '+country_name'         => ( default => 'El Salvador' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
