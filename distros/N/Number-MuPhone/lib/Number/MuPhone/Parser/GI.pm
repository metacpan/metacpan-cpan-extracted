package Number::MuPhone::Parser::GI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GI'             );
has '+country_code'         => ( default => '350'             );
has '+country_name'         => ( default => 'Gibraltar' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
