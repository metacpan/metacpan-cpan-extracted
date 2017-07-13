package Number::MuPhone::Parser::SI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SI'             );
has '+country_code'         => ( default => '386'             );
has '+country_name'         => ( default => 'Slovenia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
