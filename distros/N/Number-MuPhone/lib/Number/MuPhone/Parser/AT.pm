package Number::MuPhone::Parser::AT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AT'             );
has '+country_code'         => ( default => '43'             );
has '+country_name'         => ( default => 'Austria' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
