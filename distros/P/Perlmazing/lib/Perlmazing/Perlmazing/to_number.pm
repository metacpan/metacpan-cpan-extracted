use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

sub main {
	no warnings;
	if (not defined $_[0]) {
		$_[0] = 0;
	} elsif (is_number $_[0]) {
		$_[0] = eval "$_[0]";
	} else {
		$_[0] =~ s/\D+//g;
		$_[0] += 0;
	}
}

1;