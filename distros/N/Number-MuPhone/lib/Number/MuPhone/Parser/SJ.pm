package Number::MuPhone::Parser::SJ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SJ'             );
has '+country_code'         => ( default => '47'             );
has '+country_name'         => ( default => 'Svalbard and Jan Mayen' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
