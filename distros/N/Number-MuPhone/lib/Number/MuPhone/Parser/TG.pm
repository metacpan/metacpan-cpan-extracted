package Number::MuPhone::Parser::TG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TG'             );
has '+country_code'         => ( default => '228'             );
has '+country_name'         => ( default => 'Togo' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
