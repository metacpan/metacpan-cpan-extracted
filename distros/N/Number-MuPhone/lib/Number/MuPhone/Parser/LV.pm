package Number::MuPhone::Parser::LV;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LV'             );
has '+country_code'         => ( default => '371'             );
has '+country_name'         => ( default => 'Latvia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
