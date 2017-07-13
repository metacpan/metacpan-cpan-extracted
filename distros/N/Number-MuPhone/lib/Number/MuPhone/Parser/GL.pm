package Number::MuPhone::Parser::GL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GL'             );
has '+country_code'         => ( default => '299'             );
has '+country_name'         => ( default => 'Greenland' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
