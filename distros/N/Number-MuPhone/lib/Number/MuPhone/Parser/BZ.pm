package Number::MuPhone::Parser::BZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BZ'             );
has '+country_code'         => ( default => '501'             );
has '+country_name'         => ( default => 'Belize' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
