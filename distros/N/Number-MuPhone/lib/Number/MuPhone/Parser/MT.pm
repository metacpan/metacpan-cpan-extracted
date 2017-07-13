package Number::MuPhone::Parser::MT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MT'             );
has '+country_code'         => ( default => '356'             );
has '+country_name'         => ( default => 'Malta' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
