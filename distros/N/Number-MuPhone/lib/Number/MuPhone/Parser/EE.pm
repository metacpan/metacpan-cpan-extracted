package Number::MuPhone::Parser::EE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'EE'             );
has '+country_code'         => ( default => '372'             );
has '+country_name'         => ( default => 'Estonia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
