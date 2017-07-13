package Number::MuPhone::Parser::GQ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GQ'             );
has '+country_code'         => ( default => '240'             );
has '+country_name'         => ( default => 'Equatorial Guinea' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
