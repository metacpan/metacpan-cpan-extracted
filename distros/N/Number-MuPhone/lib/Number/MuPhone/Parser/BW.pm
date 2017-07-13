package Number::MuPhone::Parser::BW;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BW'             );
has '+country_code'         => ( default => '267'             );
has '+country_name'         => ( default => 'Botswana' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
