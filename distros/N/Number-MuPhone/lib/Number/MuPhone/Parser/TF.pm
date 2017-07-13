package Number::MuPhone::Parser::TF;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TF'             );
has '+country_code'         => ( default => '596'             );
has '+country_name'         => ( default => 'French Southern Territories' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
