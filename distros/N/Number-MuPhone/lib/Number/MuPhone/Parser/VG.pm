package Number::MuPhone::Parser::VG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'VG'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Virgin Islands' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
