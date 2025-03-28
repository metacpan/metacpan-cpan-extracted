use Perlmazing qw(define not_empty);
use Scalar::Util qw(looks_like_number);

sub main ($) {
	my $i = shift;
	no warnings;
	return 0 unless not_empty($i);
	return 0 if $i =~ /[;:\s\n&=\$%\@\(\)\*]/;
	return 0 if $i =~ /[^e][\+\-]/;
	return 1 if $i =~ /^0x\d+$/i; # Not detected by Scalar::Util
	$i =~ s/(\d)_(\d)/$1$2/g; # Also not accepted by Scalar::Util
	define looks_like_number $i;;
}

