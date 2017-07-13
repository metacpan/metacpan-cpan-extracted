package Number::MuPhone::Parser::KE;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KE'             );
has '+country_code'         => ( default => '254'             );
has '+country_name'         => ( default => 'Kenya' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '000' );

1;
