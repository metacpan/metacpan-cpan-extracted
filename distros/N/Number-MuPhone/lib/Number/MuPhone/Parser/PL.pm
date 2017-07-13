package Number::MuPhone::Parser::PL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PL'             );
has '+country_code'         => ( default => '48'             );
has '+country_name'         => ( default => 'Poland' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
