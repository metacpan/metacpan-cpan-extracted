use Perlmazing::Feature;
use Taint::Util 'untaint';
our @ISA = qw(Perlmazing::Listable);

sub main {
	untaint $_[0];
}
