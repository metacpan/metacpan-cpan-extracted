package Number::MuPhone::Parser::CY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CY'             );
has '+country_code'         => ( default => '357'             );
has '+country_name'         => ( default => 'Cyprus' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
