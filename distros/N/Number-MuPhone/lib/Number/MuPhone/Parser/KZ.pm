package Number::MuPhone::Parser::KZ;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'KZ'             );
has '+country_code'         => ( default => '7'             );
has '+country_name'         => ( default => 'Kazakhstan (IDD really 8[pause]10)' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '810' );

1;
