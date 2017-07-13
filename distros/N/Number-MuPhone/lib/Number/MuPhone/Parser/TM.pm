package Number::MuPhone::Parser::TM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TM'             );
has '+country_code'         => ( default => '993'             );
has '+country_name'         => ( default => 'Turkmenistan (IDD really 8**10)' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '810' );

1;
