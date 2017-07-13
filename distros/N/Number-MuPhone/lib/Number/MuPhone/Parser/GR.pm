package Number::MuPhone::Parser::GR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GR'             );
has '+country_code'         => ( default => '30'             );
has '+country_name'         => ( default => 'Greece' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
