use Perlmazing;

sub main {
	my ($type, $val) = @_;
	ref($val) eq $type;
}

