package Number::MuPhone::Parser::TA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TA'             );
has '+country_code'         => ( default => '290'             );
has '+country_name'         => ( default => 'Tristan da Cunha - kinda sorta part of Saint Helena' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
