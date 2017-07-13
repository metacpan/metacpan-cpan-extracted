package Number::MuPhone::Parser::LS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LS'             );
has '+country_code'         => ( default => '266'             );
has '+country_name'         => ( default => 'Lesotho' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
