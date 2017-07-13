package Number::MuPhone::Parser::CK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CK'             );
has '+country_code'         => ( default => '682'             );
has '+country_name'         => ( default => 'Cook Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
