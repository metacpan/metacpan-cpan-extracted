package Number::MuPhone::Parser::PR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PR'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Puerto Rico' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
