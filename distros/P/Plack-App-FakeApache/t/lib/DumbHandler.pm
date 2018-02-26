package DumbHandler;
use warnings;
use strict;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK);



sub handler {
	my $r = shift;
	$r->print('HelloWorld');
	return Apache2::Const::OK;
}

1;
