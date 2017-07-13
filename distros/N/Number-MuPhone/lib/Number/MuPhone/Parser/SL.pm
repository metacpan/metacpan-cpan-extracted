package Number::MuPhone::Parser::SL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SL'             );
has '+country_code'         => ( default => '232'             );
has '+country_name'         => ( default => 'Sierra Leone' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
