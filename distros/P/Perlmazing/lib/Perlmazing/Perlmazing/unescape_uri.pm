use Perlmazing;
use URI::Escape;
our @ISA = qw(Perlmazing::Listable);

sub main {
	if (defined $_[0]) {
		$_[0] =~ s/\+/%20/g;
		$_[0] = uri_unescape($_[0]);
	}
}

1;