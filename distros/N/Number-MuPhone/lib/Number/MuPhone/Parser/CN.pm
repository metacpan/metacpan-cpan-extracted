package Number::MuPhone::Parser::CN;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'CN'             );
has '+country_code'         => ( default => '86'             );
has '+country_name'         => ( default => 'China' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
