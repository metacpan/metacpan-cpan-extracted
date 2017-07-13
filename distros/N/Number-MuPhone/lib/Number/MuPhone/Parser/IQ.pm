package Number::MuPhone::Parser::IQ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IQ'             );
has '+country_code'         => ( default => '964'             );
has '+country_name'         => ( default => 'Iraq' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
