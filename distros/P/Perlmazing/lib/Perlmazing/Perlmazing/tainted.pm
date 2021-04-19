use Perlmazing::Feature;
use Taint::Util ();

*main = *Taint::Util::tainted;
