package Number::MuPhone::Parser::YE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'YE'             );
has '+country_code'         => ( default => '967'             );
has '+country_name'         => ( default => 'Yemen' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
