package Number::MuPhone::Parser::CW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CW'             );
has '+country_code'         => ( default => '599'             );
has '+country_name'         => ( default => 'Curacao' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
