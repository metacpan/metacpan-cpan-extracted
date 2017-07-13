package Number::MuPhone::Parser::TV;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TV'             );
has '+country_code'         => ( default => '688'             );
has '+country_name'         => ( default => 'Tuvalu' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
