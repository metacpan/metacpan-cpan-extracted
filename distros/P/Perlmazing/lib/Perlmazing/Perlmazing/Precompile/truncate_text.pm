use Perlmazing;

sub main ($$) {
	my ($str, $size) = @_;
	return '' unless defined $str and length $str;
	return unless is_number $size;
	my $length = length $str;
	return $str if $length <= $size;
	my $next = substr $str, $size, 1;
	$str = substr $str, 0, $size;
	if ((my $index = rindex($str, ' ')) != -1) {
		unless ($next eq ' ') {
			$str = substr $str, 0, $index;
		}
	}
	$str =~ s/\s+$//;
	$str;
}

1;
