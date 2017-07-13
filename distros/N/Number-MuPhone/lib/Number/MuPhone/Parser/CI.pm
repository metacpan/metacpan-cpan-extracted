package Number::MuPhone::Parser::CI;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'                   => ( default => 'CI'             );
has '+country_code'              => ( default => '225'            );
has '+country_name'              => ( default => 'Cote D\'Ivoire' );
has '+_national_dial_prefix'      => ( default => ''               );
has '+_international_dial_prefix' => ( default => '00'             );

1;
