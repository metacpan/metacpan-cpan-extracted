package POE::Test::DondeEstan;
$POE::Test::DondeEstan::VERSION = '1.360';
use warnings;
use strict;

use File::Spec;

# It's a pun on Marco Polo, the swimming game, and Marco A. Manzo,
# this cool dude I know.  Hi, Marco!

sub marco {
	my @aqui = File::Spec->splitdir(__FILE__);
	pop @aqui;
	return File::Spec->catdir(@aqui);
}

1;
