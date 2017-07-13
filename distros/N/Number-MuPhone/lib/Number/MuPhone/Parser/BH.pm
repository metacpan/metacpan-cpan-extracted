package Number::MuPhone::Parser::BH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BH'             );
has '+country_code'         => ( default => '973'             );
has '+country_name'         => ( default => 'Bahrain' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
