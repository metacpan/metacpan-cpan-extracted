use Perlmazing;
use Scalar::Util;

sub main ($) {
	define Scalar::Util::blessed($_[0]);
}

