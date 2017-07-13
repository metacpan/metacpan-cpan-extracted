package Number::MuPhone::Parser::AF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AF'             );
has '+country_code'         => ( default => '93'             );
has '+country_name'         => ( default => 'Afghanistan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
