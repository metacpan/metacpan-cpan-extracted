package Number::MuPhone::Parser::MS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MS'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Montserrat' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
