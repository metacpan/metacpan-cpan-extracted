package Number::MuPhone::Parser::BQ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BQ'             );
has '+country_code'         => ( default => '599'             );
has '+country_name'         => ( default => 'Bonaire' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
