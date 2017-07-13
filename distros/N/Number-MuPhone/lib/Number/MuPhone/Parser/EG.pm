package Number::MuPhone::Parser::EG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'EG'             );
has '+country_code'         => ( default => '20'             );
has '+country_name'         => ( default => 'Egypt' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
