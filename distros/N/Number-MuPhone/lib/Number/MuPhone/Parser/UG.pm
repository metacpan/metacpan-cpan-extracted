package Number::MuPhone::Parser::UG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'UG'             );
has '+country_code'         => ( default => '256'             );
has '+country_name'         => ( default => 'Uganda' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '000' );

1;
