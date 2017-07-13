package Number::MuPhone::Parser::QA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'QA'             );
has '+country_code'         => ( default => '974'             );
has '+country_name'         => ( default => 'Qatar' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
