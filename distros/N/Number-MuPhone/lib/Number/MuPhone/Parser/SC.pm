package Number::MuPhone::Parser::SC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SC'             );
has '+country_code'         => ( default => '248'             );
has '+country_name'         => ( default => 'Seychelles' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
