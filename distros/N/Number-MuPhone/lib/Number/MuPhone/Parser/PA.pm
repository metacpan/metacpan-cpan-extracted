package Number::MuPhone::Parser::PA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PA'             );
has '+country_code'         => ( default => '507'             );
has '+country_name'         => ( default => 'Panama' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
