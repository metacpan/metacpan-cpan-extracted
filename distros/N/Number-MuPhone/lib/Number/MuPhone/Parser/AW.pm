package Number::MuPhone::Parser::AW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AW'             );
has '+country_code'         => ( default => '297'             );
has '+country_name'         => ( default => 'Aruba' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
