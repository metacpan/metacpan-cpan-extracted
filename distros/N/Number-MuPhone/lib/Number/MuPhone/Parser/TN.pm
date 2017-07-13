package Number::MuPhone::Parser::TN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TN'             );
has '+country_code'         => ( default => '216'             );
has '+country_name'         => ( default => 'Tunisia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
