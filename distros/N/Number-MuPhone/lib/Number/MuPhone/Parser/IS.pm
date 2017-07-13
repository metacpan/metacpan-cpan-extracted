package Number::MuPhone::Parser::IS;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'IS'             );
has '+country_code'         => ( default => '354'             );
has '+country_name'         => ( default => 'Iceland' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
