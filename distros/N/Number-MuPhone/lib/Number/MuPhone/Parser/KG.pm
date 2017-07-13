package Number::MuPhone::Parser::KG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KG'             );
has '+country_code'         => ( default => '996'             );
has '+country_name'         => ( default => 'Kyrgyzstan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
