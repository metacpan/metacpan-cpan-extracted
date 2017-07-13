package Number::MuPhone::Parser::CH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CH'             );
has '+country_code'         => ( default => '41'             );
has '+country_name'         => ( default => 'Switzerland' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
