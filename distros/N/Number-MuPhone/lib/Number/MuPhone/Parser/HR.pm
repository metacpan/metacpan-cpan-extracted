package Number::MuPhone::Parser::HR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'HR'             );
has '+country_code'         => ( default => '385'             );
has '+country_name'         => ( default => 'Croatia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
