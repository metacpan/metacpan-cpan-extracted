package Number::MuPhone::Parser::MH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MH'             );
has '+country_code'         => ( default => '692'             );
has '+country_name'         => ( default => 'Marshall Islands' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
