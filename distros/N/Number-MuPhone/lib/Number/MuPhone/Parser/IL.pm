package Number::MuPhone::Parser::IL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IL'             );
has '+country_code'         => ( default => '972'             );
has '+country_name'         => ( default => 'Israel' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
