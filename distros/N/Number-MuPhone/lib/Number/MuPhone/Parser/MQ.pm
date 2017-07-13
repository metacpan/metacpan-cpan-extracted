package Number::MuPhone::Parser::MQ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MQ'             );
has '+country_code'         => ( default => '596'             );
has '+country_name'         => ( default => 'Martinique' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
