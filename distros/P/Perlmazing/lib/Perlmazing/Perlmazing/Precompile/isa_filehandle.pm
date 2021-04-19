use Perlmazing;
use Scalar::Util 'openhandle';

sub main ($) {
	define openhandle $_[0];
}
