package Number::MuPhone::Parser::LY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LY'             );
has '+country_code'         => ( default => '218'             );
has '+country_name'         => ( default => 'Libyan Arab Jamahiriya' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
