package Number::MuPhone::Parser::WS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'WS'             );
has '+country_code'         => ( default => '685'             );
has '+country_name'         => ( default => 'Samoa (Western)' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '0' );

1;
