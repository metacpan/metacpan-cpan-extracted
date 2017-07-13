package Number::MuPhone::Parser::NZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NZ'             );
has '+country_code'         => ( default => '64'             );
has '+country_name'         => ( default => 'New Zealand' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
