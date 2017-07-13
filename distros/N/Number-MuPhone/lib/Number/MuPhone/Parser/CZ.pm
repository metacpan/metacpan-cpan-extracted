package Number::MuPhone::Parser::CZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CZ'             );
has '+country_code'         => ( default => '420'             );
has '+country_name'         => ( default => 'Czech Republic' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
