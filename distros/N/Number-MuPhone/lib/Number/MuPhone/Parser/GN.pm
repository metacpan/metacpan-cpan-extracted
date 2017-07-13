package Number::MuPhone::Parser::GN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'GN'             );
has '+country_code'         => ( default => '224'             );
has '+country_name'         => ( default => 'Guinea' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
