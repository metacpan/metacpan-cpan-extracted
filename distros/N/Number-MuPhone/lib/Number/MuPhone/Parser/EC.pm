package Number::MuPhone::Parser::EC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'EC'             );
has '+country_code'         => ( default => '593'             );
has '+country_name'         => ( default => 'Ecuador' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
