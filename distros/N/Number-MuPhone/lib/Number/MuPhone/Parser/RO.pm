package Number::MuPhone::Parser::RO;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'RO'             );
has '+country_code'         => ( default => '40'             );
has '+country_name'         => ( default => 'Romania' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
