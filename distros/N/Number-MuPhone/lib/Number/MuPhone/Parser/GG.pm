package Number::MuPhone::Parser::GG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GG'             );
has '+country_code'         => ( default => '44'             );
has '+country_name'         => ( default => 'Guernsey' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
