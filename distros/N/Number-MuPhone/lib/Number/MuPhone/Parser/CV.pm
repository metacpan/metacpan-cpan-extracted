package Number::MuPhone::Parser::CV;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CV'             );
has '+country_code'         => ( default => '238'             );
has '+country_name'         => ( default => 'Cape Verde Islands' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '0' );

1;
