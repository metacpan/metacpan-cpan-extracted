package Number::MuPhone::Parser::DE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'DE'             );
has '+country_code'         => ( default => '49'             );
has '+country_name'         => ( default => 'Germany' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
