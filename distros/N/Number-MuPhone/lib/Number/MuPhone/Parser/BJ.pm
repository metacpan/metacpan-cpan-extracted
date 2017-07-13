package Number::MuPhone::Parser::BJ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BJ'             );
has '+country_code'         => ( default => '229'             );
has '+country_name'         => ( default => 'Benin' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
