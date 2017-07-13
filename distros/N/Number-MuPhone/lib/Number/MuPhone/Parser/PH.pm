package Number::MuPhone::Parser::PH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PH'             );
has '+country_code'         => ( default => '63'             );
has '+country_name'         => ( default => 'Philippines' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
