package Number::MuPhone::Parser::MA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MA'             );
has '+country_code'         => ( default => '212'             );
has '+country_name'         => ( default => 'Morocco' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
