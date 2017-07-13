package Number::MuPhone::Parser::FK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'FK'             );
has '+country_code'         => ( default => '500'             );
has '+country_name'         => ( default => 'Falkland Islands (Malvinas)' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
