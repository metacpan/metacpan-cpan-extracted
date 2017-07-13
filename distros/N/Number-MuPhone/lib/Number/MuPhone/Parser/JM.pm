package Number::MuPhone::Parser::JM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'JM'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Jamaica' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
