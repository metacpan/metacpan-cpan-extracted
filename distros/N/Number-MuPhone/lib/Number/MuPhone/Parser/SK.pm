package Number::MuPhone::Parser::SK;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'SK'             );
has '+country_code'         => ( default => '421'             );
has '+country_name'         => ( default => 'Slovakia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
