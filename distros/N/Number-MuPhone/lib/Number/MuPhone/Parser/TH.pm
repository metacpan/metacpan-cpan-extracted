package Number::MuPhone::Parser::TH;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TH'             );
has '+country_code'         => ( default => '66'             );
has '+country_name'         => ( default => 'Thailand' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '001' );

1;
