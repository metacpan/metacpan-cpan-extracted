package Number::MuPhone::Parser::BI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BI'             );
has '+country_code'         => ( default => '257'             );
has '+country_name'         => ( default => 'Burundi' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
