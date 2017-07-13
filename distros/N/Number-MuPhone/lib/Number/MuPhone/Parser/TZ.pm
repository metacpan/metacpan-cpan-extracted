package Number::MuPhone::Parser::TZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TZ'             );
has '+country_code'         => ( default => '255'             );
has '+country_name'         => ( default => 'Tanzania' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '000' );

1;
