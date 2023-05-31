use Perlmazing;
use Encode;
our @ISA = qw(Perlmazing::Listable);

sub main {
	$_[0] = Encode::encode('utf8', $_[0]) if defined $_[0] and not is_utf8 $_[0];
}

1;