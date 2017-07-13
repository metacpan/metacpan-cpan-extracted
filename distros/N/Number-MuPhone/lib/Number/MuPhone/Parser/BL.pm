package Number::MuPhone::Parser::BL;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BL'             );
has '+country_code'         => ( default => '590'             );
has '+country_name'         => ( default => 'Saint Barthélemy' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
