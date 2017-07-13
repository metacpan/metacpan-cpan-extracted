package Number::MuPhone::Parser::MF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MF'             );
has '+country_code'         => ( default => '590'             );
has '+country_name'         => ( default => 'Saint Martin' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
