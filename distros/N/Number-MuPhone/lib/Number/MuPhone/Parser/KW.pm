package Number::MuPhone::Parser::KW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KW'             );
has '+country_code'         => ( default => '965'             );
has '+country_name'         => ( default => 'Kuwait' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
