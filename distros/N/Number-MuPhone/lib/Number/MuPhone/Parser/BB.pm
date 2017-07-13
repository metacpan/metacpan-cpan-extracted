package Number::MuPhone::Parser::BB;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BB'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Barbados' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
