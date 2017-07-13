package Number::MuPhone::Parser::ZW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ZW'             );
has '+country_code'         => ( default => '263'             );
has '+country_name'         => ( default => 'Zimbabwe' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
