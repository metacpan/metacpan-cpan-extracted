package Number::MuPhone::Parser::LR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LR'             );
has '+country_code'         => ( default => '231'             );
has '+country_name'         => ( default => 'Liberia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
