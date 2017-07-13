package Number::MuPhone::Parser::CC;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CC'             );
has '+country_code'         => ( default => '61'             );
has '+country_name'         => ( default => 'Cocos (Keeling) Islands' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '0011' );

1;
