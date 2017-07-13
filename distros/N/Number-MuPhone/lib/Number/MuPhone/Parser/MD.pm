package Number::MuPhone::Parser::MD;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'MD'             );
has '+country_code'         => ( default => '373'             );
has '+country_name'         => ( default => 'Moldova' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '00' );

1;
