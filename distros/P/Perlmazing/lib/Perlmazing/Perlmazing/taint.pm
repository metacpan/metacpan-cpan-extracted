use Perlmazing::Feature;
use Taint::Util 'taint';
our @ISA = qw(Perlmazing::Listable);

sub main {
	taint $_[0];
}
