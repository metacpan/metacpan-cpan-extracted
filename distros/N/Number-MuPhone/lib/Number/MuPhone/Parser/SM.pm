package Number::MuPhone::Parser::SM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SM'             );
has '+country_code'         => ( default => '378'             );
has '+country_name'         => ( default => 'San Marino - area code is always 0549' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
