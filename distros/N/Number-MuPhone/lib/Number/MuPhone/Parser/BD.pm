package Number::MuPhone::Parser::BD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BD'             );
has '+country_code'         => ( default => '880'             );
has '+country_name'         => ( default => 'Bangladesh' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
