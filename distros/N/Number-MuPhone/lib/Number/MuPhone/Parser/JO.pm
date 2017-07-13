package Number::MuPhone::Parser::JO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'JO'             );
has '+country_code'         => ( default => '962'             );
has '+country_name'         => ( default => 'Jordan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
