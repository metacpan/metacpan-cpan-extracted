package Number::MuPhone::Parser::UY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'UY'             );
has '+country_code'         => ( default => '598'             );
has '+country_name'         => ( default => 'Uruguay' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
