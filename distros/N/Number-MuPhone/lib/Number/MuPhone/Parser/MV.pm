package Number::MuPhone::Parser::MV;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MV'             );
has '+country_code'         => ( default => '960'             );
has '+country_name'         => ( default => 'Maldives' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
