package Number::MuPhone::Parser::SN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SN'             );
has '+country_code'         => ( default => '221'             );
has '+country_name'         => ( default => 'Senegal' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
