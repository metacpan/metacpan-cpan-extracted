package Number::MuPhone::Parser::IO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IO'             );
has '+country_code'         => ( default => '246'             );
has '+country_name'         => ( default => 'British Indian Ocean Territory' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
