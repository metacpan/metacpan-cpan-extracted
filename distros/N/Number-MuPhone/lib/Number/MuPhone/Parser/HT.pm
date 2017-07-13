package Number::MuPhone::Parser::HT;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'HT'             );
has '+country_code'         => ( default => '509'             );
has '+country_name'         => ( default => 'Haiti' );
has '+_national_dial_prefix'      => ( default => '' );
has '+_international_dial_prefix' => ( default => '00' );

1;
