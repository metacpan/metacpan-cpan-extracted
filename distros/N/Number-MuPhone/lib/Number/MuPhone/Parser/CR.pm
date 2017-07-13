package Number::MuPhone::Parser::CR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CR'             );
has '+country_code'         => ( default => '506'             );
has '+country_name'         => ( default => 'Costa Rica' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
