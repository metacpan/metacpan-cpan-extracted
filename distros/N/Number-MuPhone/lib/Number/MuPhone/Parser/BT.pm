package Number::MuPhone::Parser::BT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BT'             );
has '+country_code'         => ( default => '975'             );
has '+country_name'         => ( default => 'Bhutan' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
