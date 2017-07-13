package Number::MuPhone::Parser::ZM;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'ZM'             );
has '+country_code'         => ( default => '260'             );
has '+country_name'         => ( default => 'Zambia' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
