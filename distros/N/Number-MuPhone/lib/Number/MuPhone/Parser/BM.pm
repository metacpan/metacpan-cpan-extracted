package Number::MuPhone::Parser::BM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BM'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Bermuda' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
