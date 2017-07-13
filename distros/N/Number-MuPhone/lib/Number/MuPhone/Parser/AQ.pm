package Number::MuPhone::Parser::AQ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AQ'             );
has '+country_code'         => ( default => '672'             );
has '+country_name'         => ( default => 'Antarctica' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '' );

1;
