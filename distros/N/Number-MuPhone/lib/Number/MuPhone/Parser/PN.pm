package Number::MuPhone::Parser::PN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PN'             );
has '+country_code'         => ( default => '872'             );
has '+country_name'         => ( default => 'Pitcairn' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '' );

1;
