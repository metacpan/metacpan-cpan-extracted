package Number::MuPhone::Parser::GU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GU'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Guam' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
