package Number::MuPhone::Parser::GA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GA'             );
has '+country_code'         => ( default => '241'             );
has '+country_name'         => ( default => 'Gabonese Republic' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
