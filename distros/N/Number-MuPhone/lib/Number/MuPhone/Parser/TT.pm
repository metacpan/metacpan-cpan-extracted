package Number::MuPhone::Parser::TT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TT'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Trinidad and Tobago' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
