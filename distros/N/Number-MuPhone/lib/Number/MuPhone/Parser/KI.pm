package Number::MuPhone::Parser::KI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KI'             );
has '+country_code'         => ( default => '686'             );
has '+country_name'         => ( default => 'Kiribati' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
