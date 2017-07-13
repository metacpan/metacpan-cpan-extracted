package Number::MuPhone::Parser::BF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BF'             );
has '+country_code'         => ( default => '226'             );
has '+country_name'         => ( default => 'Burkina Faso' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
