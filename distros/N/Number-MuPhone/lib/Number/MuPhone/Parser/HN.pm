package Number::MuPhone::Parser::HN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'HN'             );
has '+country_code'         => ( default => '504'             );
has '+country_name'         => ( default => 'Honduras' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
