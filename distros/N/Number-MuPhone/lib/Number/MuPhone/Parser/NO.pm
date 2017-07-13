package Number::MuPhone::Parser::NO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NO'             );
has '+country_code'         => ( default => '47'             );
has '+country_name'         => ( default => 'Norway' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
