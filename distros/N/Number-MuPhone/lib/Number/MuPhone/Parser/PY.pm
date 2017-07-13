package Number::MuPhone::Parser::PY;
use Moo;

extends 'Number::MuPhone::Parser';

has '+country'              => ( default => 'PY'             );
has '+country_code'         => ( default => '595'             );
has '+country_name'         => ( default => 'Paraguay' );
has '+_national_dial_prefix'      => ( default => '0' );
has '+_international_dial_prefix' => ( default => '002' );

1;
