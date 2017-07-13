package Number::MuPhone::Parser::OM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'OM'             );
has '+country_code'         => ( default => '968'             );
has '+country_name'         => ( default => 'Oman' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
