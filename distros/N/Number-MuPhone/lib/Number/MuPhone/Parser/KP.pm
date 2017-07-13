package Number::MuPhone::Parser::KP;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KP'             );
has '+country_code'         => ( default => '850'             );
has '+country_name'         => ( default => 'Korea' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
