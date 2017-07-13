package Number::MuPhone::Parser::AI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AI'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Anguilla' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
