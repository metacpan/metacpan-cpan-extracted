package Number::MuPhone::Parser::RS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'RS'             );
has '+country_code'         => ( default => '381'             );
has '+country_name'         => ( default => 'Serbia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
