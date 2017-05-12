use Perlmazing;
use Encode;

sub main ($) {
	my $str = shift;
	return unless not is_empty $str;
	my $str2 = $str;
	eval {
		$str = Encode::decode('utf8', $str, Encode::FB_CROAK);
	};
	return 0 if $@;
	return 1 if defined($str) and $str2 ne $str;
	return 0;
}

