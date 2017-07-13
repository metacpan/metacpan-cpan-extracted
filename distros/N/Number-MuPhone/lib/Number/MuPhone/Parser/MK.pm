package Number::MuPhone::Parser::MK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MK'             );
has '+country_code'         => ( default => '389'             );
has '+country_name'         => ( default => 'Macedonia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
