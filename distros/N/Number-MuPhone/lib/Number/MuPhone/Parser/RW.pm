package Number::MuPhone::Parser::RW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'RW'             );
has '+country_code'         => ( default => '250'             );
has '+country_name'         => ( default => 'Rwanda' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
