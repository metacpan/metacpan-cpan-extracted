package Number::MuPhone::Parser::LA;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'LA'             );
has '+country_code'         => ( default => '856'             );
has '+country_name'         => ( default => 'Laos' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
