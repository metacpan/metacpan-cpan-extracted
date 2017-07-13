package Number::MuPhone::Parser::SE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SE'             );
has '+country_code'         => ( default => '46'             );
has '+country_name'         => ( default => 'Sweden' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
