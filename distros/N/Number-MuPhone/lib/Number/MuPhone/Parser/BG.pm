package Number::MuPhone::Parser::BG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BG'             );
has '+country_code'         => ( default => '359'             );
has '+country_name'         => ( default => 'Bulgaria' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
