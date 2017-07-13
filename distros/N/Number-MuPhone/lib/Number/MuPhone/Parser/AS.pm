package Number::MuPhone::Parser::AS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AS'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'American Samoa' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
