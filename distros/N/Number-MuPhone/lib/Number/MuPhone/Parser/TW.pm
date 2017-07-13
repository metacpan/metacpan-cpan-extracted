package Number::MuPhone::Parser::TW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'TW'             );
has '+country_code'         => ( default => '886'             );
has '+country_name'         => ( default => 'Taiwan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '002' );

1;
