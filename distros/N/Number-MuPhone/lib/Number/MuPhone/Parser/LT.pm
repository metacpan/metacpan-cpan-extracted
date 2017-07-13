package Number::MuPhone::Parser::LT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LT'             );
has '+country_code'         => ( default => '370'             );
has '+country_name'         => ( default => 'Lithuania' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '00' );

1;
