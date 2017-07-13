package Number::MuPhone::Parser::NF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NF'             );
has '+country_code'         => ( default => '672'             );
has '+country_name'         => ( default => 'Norfolk Island' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
