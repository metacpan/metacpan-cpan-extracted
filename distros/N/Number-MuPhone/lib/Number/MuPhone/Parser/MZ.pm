package Number::MuPhone::Parser::MZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MZ'             );
has '+country_code'         => ( default => '258'             );
has '+country_name'         => ( default => 'Mozambique' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
