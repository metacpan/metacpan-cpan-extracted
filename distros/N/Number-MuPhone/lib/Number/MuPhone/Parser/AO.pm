package Number::MuPhone::Parser::AO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AO'             );
has '+country_code'         => ( default => '244'             );
has '+country_name'         => ( default => 'Angola' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
