package Number::MuPhone::Parser::MY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MY'             );
has '+country_code'         => ( default => '60'             );
has '+country_name'         => ( default => 'Malaysia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
