package Number::MuPhone::Parser::BO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BO'             );
has '+country_code'         => ( default => '591'             );
has '+country_name'         => ( default => 'Bolivia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
