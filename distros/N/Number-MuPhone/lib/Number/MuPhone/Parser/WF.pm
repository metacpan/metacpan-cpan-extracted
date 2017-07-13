package Number::MuPhone::Parser::WF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'WF'             );
has '+country_code'         => ( default => '681'             );
has '+country_name'         => ( default => 'Wallis and Futuna Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
