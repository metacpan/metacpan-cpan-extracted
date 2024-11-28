use Perlmazing::Feature;
use Taint::Util ();
our @ISA = qw(Perlmazing::Listable);

sub main {
	Taint::Util::taint($_[0]);
}
