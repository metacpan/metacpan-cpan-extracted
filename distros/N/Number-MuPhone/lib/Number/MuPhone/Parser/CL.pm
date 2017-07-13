package Number::MuPhone::Parser::CL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CL'             );
has '+country_code'         => ( default => '56'             );
has '+country_name'         => ( default => 'Chile' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
