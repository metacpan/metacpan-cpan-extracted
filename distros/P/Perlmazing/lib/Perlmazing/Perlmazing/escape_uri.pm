use Perlmazing;
use URI::Escape;
our @ISA = qw(Perlmazing::Listable);

sub main {
	$_[0] = uri_escape($_[0]) if defined $_[0];
}

1;