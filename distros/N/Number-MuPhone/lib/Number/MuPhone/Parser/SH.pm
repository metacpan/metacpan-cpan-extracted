package Number::MuPhone::Parser::SH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SH'             );
has '+country_code'         => ( default => '290'             );
has '+country_name'         => ( default => 'Saint Helena' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
