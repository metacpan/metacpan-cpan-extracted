package Number::MuPhone::Parser::PG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PG'             );
has '+country_code'         => ( default => '675'             );
has '+country_name'         => ( default => 'Papua New Guinea' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
