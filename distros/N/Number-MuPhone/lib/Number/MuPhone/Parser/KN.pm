package Number::MuPhone::Parser::KN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KN'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Saint Kitts and Nevis' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
