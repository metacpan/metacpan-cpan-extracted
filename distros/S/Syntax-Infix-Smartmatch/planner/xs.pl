use strict;
use warnings;

load_module('Dist::Build::XS');

my %args;
if ($] >= 5.038) {
	load_module('Dist::Build::XS::Import');
	$args{import} = 'XS::Parse::Infix';
}

add_xs(%args);
