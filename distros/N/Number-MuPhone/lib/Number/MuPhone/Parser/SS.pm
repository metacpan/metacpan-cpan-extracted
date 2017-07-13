package Number::MuPhone::Parser::SS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SS'             );
has '+country_code'         => ( default => '211'             );
has '+country_name'         => ( default => 'South Sudan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
