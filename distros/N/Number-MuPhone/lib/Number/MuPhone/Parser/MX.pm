package Number::MuPhone::Parser::MX;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MX'             );
has '+country_code'         => ( default => '52'             );
has '+country_name'         => ( default => 'Mexico' );
has '+_national_dial_prefix'      => ( default => '01' );
has '+_international_dial_prefix' => ( default => '00' );

1;
