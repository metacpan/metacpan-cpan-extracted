package Number::MuPhone::Parser::IN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IN'             );
has '+country_code'         => ( default => '91'             );
has '+country_name'         => ( default => 'India' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
