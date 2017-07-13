package Number::MuPhone::Parser::GE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GE'             );
has '+country_code'         => ( default => '995'             );
has '+country_name'         => ( default => 'Georgia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
