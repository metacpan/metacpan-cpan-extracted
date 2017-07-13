package Number::MuPhone::Parser::UZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'UZ'             );
has '+country_code'         => ( default => '998'             );
has '+country_name'         => ( default => 'Uzbekistan (IDD really 8**10)' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '810' );

1;
