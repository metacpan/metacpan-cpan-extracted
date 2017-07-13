package Number::MuPhone::Parser::EH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'EH'             );
has '+country_code'         => ( default => '212'             );
has '+country_name'         => ( default => 'Western Sahara' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
