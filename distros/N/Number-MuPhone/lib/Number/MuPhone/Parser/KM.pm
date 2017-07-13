package Number::MuPhone::Parser::KM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KM'             );
has '+country_code'         => ( default => '269'             );
has '+country_name'         => ( default => 'Comoros' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
