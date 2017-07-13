package Number::MuPhone::Parser::SO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SO'             );
has '+country_code'         => ( default => '252'             );
has '+country_name'         => ( default => 'Somalia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
