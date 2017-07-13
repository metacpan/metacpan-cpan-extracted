package Number::MuPhone::Parser::BY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'BY'             );
has '+country_code'         => ( default => '375'             );
has '+country_name'         => ( default => 'Belarus (IDD really 8**10)' );
has '+_national_dial_prefix'      => ( default => '8' );
has '+_international_dial_prefix' => ( default => '810' );

1;
