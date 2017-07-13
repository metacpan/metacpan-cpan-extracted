package Number::MuPhone::Parser::GM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GM'             );
has '+country_code'         => ( default => '220'             );
has '+country_name'         => ( default => 'Gambia' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
