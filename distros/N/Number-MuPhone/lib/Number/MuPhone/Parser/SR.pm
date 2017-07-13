package Number::MuPhone::Parser::SR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SR'             );
has '+country_code'         => ( default => '597'             );
has '+country_name'         => ( default => 'Suriname' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
