package Number::MuPhone::Parser::DK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'DK'             );
has '+country_code'         => ( default => '45'             );
has '+country_name'         => ( default => 'Denmark' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
