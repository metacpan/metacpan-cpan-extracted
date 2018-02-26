package DumbHandler2;
use warnings;
use strict;

use Apache2::RequestRec ();
use Apache2::Const -compile => qw(OK DECLINED);

=head1 DumbHandler2

For testing a subclassed Apache2::Request or Apache2::RequestRec.  See
use of do_print in handler.

=cut

sub handler {
	my $r = shift;
	$r->do_print('HelloWorld');
	return Apache2::Const::OK;
}

1;
