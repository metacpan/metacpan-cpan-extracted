use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

sub main {
	$_[0] = '' unless defined $_[0];
}

1;