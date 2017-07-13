package Number::MuPhone::Parser::MW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MW'             );
has '+country_code'         => ( default => '265'             );
has '+country_name'         => ( default => 'Malawi' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
