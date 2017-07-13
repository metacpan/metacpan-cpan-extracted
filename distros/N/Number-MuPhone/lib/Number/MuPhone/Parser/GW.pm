package Number::MuPhone::Parser::GW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GW'             );
has '+country_code'         => ( default => '245'             );
has '+country_name'         => ( default => 'Guinea-Bissau' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
