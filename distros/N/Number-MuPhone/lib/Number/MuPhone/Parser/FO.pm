package Number::MuPhone::Parser::FO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'FO'             );
has '+country_code'         => ( default => '298'             );
has '+country_name'         => ( default => 'Faroe Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
