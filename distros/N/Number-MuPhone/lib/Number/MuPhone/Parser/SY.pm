package Number::MuPhone::Parser::SY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SY'             );
has '+country_code'         => ( default => '963'             );
has '+country_name'         => ( default => 'Syria' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
