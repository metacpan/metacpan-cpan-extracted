package Number::MuPhone::Parser::NANP;
use Moo;

# generic catch all for NANP numbers

extends 'Number::MuPhone::Parser::US';

has '+country'      => ( default => 'NANP'                    );
has '+country_name' => ( default => 'North America (unknown)' );

1;
