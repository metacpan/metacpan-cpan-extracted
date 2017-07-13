package Number::MuPhone::Parser::BN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BN'             );
has '+country_code'         => ( default => '673'             );
has '+country_name'         => ( default => 'Brunei Darussalam' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
