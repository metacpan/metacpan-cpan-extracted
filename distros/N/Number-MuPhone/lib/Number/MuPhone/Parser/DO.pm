package Number::MuPhone::Parser::DO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'DO'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Dominican Republic' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
