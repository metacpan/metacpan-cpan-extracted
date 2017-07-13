package Number::MuPhone::Parser::GT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GT'             );
has '+country_code'         => ( default => '502'             );
has '+country_name'         => ( default => 'Guatemala' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
