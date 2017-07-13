package Number::MuPhone::Parser::SG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SG'             );
has '+country_code'         => ( default => '65'             );
has '+country_name'         => ( default => 'Singapore' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '000' );

1;
