package Number::MuPhone::Parser::LU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LU'             );
has '+country_code'         => ( default => '352'             );
has '+country_name'         => ( default => 'Luxembourg' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
