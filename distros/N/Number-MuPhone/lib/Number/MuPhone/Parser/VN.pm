package Number::MuPhone::Parser::VN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VN'             );
has '+country_code'         => ( default => '84'             );
has '+country_name'         => ( default => 'Viet Nam' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
