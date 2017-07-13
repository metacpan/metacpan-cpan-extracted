package Number::MuPhone::Parser::FJ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'FJ'             );
has '+country_code'         => ( default => '679'             );
has '+country_name'         => ( default => 'Fiji' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
