package Number::MuPhone::Parser::KR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KR'             );
has '+country_code'         => ( default => '82'             );
has '+country_name'         => ( default => 'Korea (South)' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '001' );

1;
