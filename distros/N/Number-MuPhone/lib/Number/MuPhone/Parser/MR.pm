package Number::MuPhone::Parser::MR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MR'             );
has '+country_code'         => ( default => '222'             );
has '+country_name'         => ( default => 'Mauritania' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
