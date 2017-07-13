package Number::MuPhone::Parser::RU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'RU'             );
has '+country_code'         => ( default => '7'             );
has '+country_name'         => ( default => 'Russia 8**10 NOTE: may change to 00' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '810' );

1;
