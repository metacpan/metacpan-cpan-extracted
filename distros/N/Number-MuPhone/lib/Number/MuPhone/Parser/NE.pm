package Number::MuPhone::Parser::NE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NE'             );
has '+country_code'         => ( default => '227'             );
has '+country_name'         => ( default => 'Niger' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
