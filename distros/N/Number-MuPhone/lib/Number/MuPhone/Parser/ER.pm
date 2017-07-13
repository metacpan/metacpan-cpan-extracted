package Number::MuPhone::Parser::ER;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ER'             );
has '+country_code'         => ( default => '291'             );
has '+country_name'         => ( default => 'Eritrea' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
