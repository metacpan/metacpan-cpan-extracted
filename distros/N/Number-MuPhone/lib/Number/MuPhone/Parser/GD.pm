package Number::MuPhone::Parser::GD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GD'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Grenada' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
