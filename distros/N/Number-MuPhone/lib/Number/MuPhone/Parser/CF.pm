package Number::MuPhone::Parser::CF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CF'             );
has '+country_code'         => ( default => '236'             );
has '+country_name'         => ( default => 'Central African Republic' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
