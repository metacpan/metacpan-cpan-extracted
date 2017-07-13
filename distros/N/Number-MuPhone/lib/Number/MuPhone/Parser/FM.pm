package Number::MuPhone::Parser::FM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'FM'             );
has '+country_code'         => ( default => '691'             );
has '+country_name'         => ( default => 'Micronesia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
