package Number::MuPhone::Parser::ME;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ME'             );
has '+country_code'         => ( default => '382'             );
has '+country_name'         => ( default => 'Montenegro' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
