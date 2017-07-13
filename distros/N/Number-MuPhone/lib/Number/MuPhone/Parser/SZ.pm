package Number::MuPhone::Parser::SZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SZ'             );
has '+country_code'         => ( default => '268'             );
has '+country_name'         => ( default => 'Swaziland' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
