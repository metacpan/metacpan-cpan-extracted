package Number::MuPhone::Parser::NI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NI'             );
has '+country_code'         => ( default => '505'             );
has '+country_name'         => ( default => 'Nicaragua' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
