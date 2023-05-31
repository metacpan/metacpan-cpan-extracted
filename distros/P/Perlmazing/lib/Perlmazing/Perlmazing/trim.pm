use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

sub main {
	$_[0] =~ s/(^\s+|\s+$)//g if defined $_[0];
}

1;