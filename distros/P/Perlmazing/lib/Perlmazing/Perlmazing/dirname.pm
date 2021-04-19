use File::Basename ();
our @ISA = qw(Perlmazing::Listable);

sub main {
	$_[0] = File::Basename::dirname($_[0]) if defined $_[0];
}

1;