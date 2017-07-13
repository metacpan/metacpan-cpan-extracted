package Number::MuPhone::Parser::PF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PF'             );
has '+country_code'         => ( default => '689'             );
has '+country_name'         => ( default => 'French Polynesia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
