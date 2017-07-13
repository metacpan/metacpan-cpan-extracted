package Number::MuPhone::Parser::IT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IT'             );
has '+country_code'         => ( default => '39'             );
has '+country_name'         => ( default => 'Italy' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
