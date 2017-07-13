package Number::MuPhone::Parser::LI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LI'             );
has '+country_code'         => ( default => '423'             );
has '+country_name'         => ( default => 'Liechtenstein' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
