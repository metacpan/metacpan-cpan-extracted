package Number::MuPhone::Parser::MM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MM'             );
has '+country_code'         => ( default => '95'             );
has '+country_name'         => ( default => 'Myanmar' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
