package Number::MuPhone::Parser::CM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CM'             );
has '+country_code'         => ( default => '237'             );
has '+country_name'         => ( default => 'Cameroon' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
