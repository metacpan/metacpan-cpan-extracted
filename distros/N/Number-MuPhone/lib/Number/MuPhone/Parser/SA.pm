package Number::MuPhone::Parser::SA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SA'             );
has '+country_code'         => ( default => '966'             );
has '+country_name'         => ( default => 'Saudi Arabia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
