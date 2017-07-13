package Number::MuPhone::Parser::CO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CO'             );
has '+country_code'         => ( default => '57'             );
has '+country_name'         => ( default => 'Colombia' );
has '+_national_dial_prefix'      => ( default => '09' );
has '+_international_dial_prefix' => ( default => '009' );

1;
