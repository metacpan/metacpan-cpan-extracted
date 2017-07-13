package Number::MuPhone::Parser::PE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PE'             );
has '+country_code'         => ( default => '51'             );
has '+country_name'         => ( default => 'Peru' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
