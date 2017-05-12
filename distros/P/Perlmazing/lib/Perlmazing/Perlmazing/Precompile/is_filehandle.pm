use Perlmazing;
use Scalar::Util 'openhandle';

sub main ($) {
	openhandle $_[0];
}
