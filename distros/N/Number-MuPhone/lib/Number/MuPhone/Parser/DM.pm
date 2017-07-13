package Number::MuPhone::Parser::DM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'DM'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Dominica' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
