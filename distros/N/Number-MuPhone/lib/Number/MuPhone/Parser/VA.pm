package Number::MuPhone::Parser::VA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VA'             );
has '+country_code'         => ( default => '379'             );
has '+country_name'         => ( default => 'Holy See (Vatican City State)' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
