package Number::MuPhone::Parser::ET;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ET'             );
has '+country_code'         => ( default => '251'             );
has '+country_name'         => ( default => 'Ethiopia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
