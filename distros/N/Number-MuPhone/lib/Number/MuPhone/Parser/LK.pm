package Number::MuPhone::Parser::LK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LK'             );
has '+country_code'         => ( default => '94'             );
has '+country_name'         => ( default => 'Sri Lanka' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
