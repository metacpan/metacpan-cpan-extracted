package Number::MuPhone::Parser::VI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VI'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Virgin Islands' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
