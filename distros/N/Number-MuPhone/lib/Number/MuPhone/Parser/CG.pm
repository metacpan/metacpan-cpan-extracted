package Number::MuPhone::Parser::CG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CG'             );
has '+country_code'         => ( default => '242'             );
has '+country_name'         => ( default => 'Congo' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
