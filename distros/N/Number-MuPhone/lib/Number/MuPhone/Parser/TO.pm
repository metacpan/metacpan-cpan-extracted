package Number::MuPhone::Parser::TO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TO'             );
has '+country_code'         => ( default => '676'             );
has '+country_name'         => ( default => 'Tonga Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
