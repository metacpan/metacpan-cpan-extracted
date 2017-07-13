package Number::MuPhone::Parser::JP;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'JP'             );
has '+country_code'         => ( default => '81'             );
has '+country_name'         => ( default => 'Japan' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '010' );

1;
