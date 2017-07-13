package Number::MuPhone::Parser::ES;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ES'             );
has '+country_code'         => ( default => '34'             );
has '+country_name'         => ( default => 'Spain' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
