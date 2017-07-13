package Number::MuPhone::Parser::ST;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ST'             );
has '+country_code'         => ( default => '239'             );
has '+country_name'         => ( default => 'Sao Tome and Principe' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
