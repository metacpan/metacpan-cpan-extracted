use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

sub main {
	$_[0] = defined($_[0]) ? "$_[0]" : '';
}

1;