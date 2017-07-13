package Number::MuPhone::Parser::TR;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TR'             );
has '+country_code'         => ( default => '90'             );
has '+country_name'         => ( default => 'Turkey' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
