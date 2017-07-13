package Number::MuPhone::Parser::PS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PS'             );
has '+country_code'         => ( default => '970'             );
has '+country_name'         => ( default => 'Palestinian Territory' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
