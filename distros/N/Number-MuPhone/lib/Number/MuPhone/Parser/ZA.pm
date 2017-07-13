package Number::MuPhone::Parser::ZA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ZA'             );
has '+country_code'         => ( default => '27'             );
has '+country_name'         => ( default => 'South Africa' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
