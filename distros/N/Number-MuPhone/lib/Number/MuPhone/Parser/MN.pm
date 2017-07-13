package Number::MuPhone::Parser::MN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MN'             );
has '+country_code'         => ( default => '976'             );
has '+country_name'         => ( default => 'Mongolia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '001' );

1;
