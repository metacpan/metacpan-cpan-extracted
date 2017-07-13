package Number::MuPhone::Parser::ML;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ML'             );
has '+country_code'         => ( default => '223'             );
has '+country_name'         => ( default => 'Mali' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
