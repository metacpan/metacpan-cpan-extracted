package Number::MuPhone::Parser::AC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AC'             );
has '+country_code'         => ( default => '247'             );
has '+country_name'         => ( default => 'Ascension Island' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
