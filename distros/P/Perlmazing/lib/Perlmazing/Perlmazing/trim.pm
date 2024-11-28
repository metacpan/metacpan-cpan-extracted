use Perlmazing;
our @ISA = qw(Perlmazing::Listable);

sub main {
	if (defined $_[0]) {
    $_[0] =~ s/(^\s+|\s+$)//g;
  } else {
    $_[0] = '';
  }
}

1;