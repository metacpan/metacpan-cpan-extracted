package Number::MuPhone::Parser::NR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NR'             );
has '+country_code'         => ( default => '674'             );
has '+country_name'         => ( default => 'Nauru' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
