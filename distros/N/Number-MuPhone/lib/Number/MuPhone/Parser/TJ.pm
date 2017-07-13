package Number::MuPhone::Parser::TJ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TJ'             );
has '+country_code'         => ( default => '992'             );
has '+country_name'         => ( default => 'Tajikistan (IDD really 8**10)' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '810' );

1;
