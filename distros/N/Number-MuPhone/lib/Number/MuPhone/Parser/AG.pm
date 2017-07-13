package Number::MuPhone::Parser::AG;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'AG'             );
has '+country_code'         => ( default => '1'             );
has '+country_name'         => ( default => 'Antigua and Barbuda' );
has '+_national_dial_prefix'      => ( default => '1' );
has '+_international_dial_prefix' => ( default => '011' );

1;
