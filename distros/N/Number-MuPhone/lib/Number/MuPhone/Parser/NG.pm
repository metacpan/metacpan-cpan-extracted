package Number::MuPhone::Parser::NG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'NG'             );
has '+country_code'         => ( default => '234'             );
has '+country_name'         => ( default => 'Nigeria' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '009' );

1;
