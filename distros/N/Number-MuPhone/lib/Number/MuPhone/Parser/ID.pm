package Number::MuPhone::Parser::ID;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ID'             );
has '+country_code'         => ( default => '62'             );
has '+country_name'         => ( default => 'Indonesia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '001' );

1;
