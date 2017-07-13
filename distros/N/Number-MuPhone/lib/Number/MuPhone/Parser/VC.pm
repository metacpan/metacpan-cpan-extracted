package Number::MuPhone::Parser::VC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VC'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Saint Vincent and the Grenadines' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
