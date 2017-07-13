package Number::MuPhone::Parser::AU;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AU'             );
has '+country_code'         => ( default => '61'             );
has '+country_name'         => ( default => 'Australia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '0011' );

1;
