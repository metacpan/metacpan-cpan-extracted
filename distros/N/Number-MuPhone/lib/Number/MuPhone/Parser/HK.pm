package Number::MuPhone::Parser::HK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'HK'             );
has '+country_code'         => ( default => '852'             );
has '+country_name'         => ( default => 'Hong Kong' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '001' );

1;
