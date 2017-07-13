package Number::MuPhone::Parser::MO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MO'             );
has '+country_code'         => ( default => '853'             );
has '+country_name'         => ( default => 'Macao' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
