package Number::MuPhone::Parser::TL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TL'             );
has '+country_code'         => ( default => '670'             );
has '+country_name'         => ( default => 'Timor-Leste' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
