package Number::MuPhone::Parser::SB;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SB'             );
has '+country_code'         => ( default => '677'             );
has '+country_name'         => ( default => 'Solomon Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
