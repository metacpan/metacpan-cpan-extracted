package Number::MuPhone::Parser::LC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LC'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Saint Lucia' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
