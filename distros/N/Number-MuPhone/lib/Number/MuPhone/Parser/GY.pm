package Number::MuPhone::Parser::GY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GY'             );
has '+country_code'         => ( default => '592'             );
has '+country_name'         => ( default => 'Guyana' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '001' );

1;
