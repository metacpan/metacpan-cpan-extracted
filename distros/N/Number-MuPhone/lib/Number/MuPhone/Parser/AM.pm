package Number::MuPhone::Parser::AM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AM'             );
has '+country_code'         => ( default => '374'             );
has '+country_name'         => ( default => 'Armenia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
