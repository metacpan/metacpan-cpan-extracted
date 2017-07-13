package Number::MuPhone::Parser::GH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GH'             );
has '+country_code'         => ( default => '233'             );
has '+country_name'         => ( default => 'Ghana' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
