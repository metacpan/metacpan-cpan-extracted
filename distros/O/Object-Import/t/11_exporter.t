use warnings; use strict;
use Test::More tests => 3;

use Object::Import ();

{
package X;
use Exporter;
our @ISA = "Exporter";
sub greet { 
	my($o, $a) = @_; 
	"hello $a from $o"; 
}
}

{
package G;
use Test::More;
our %nm;
import Object::Import "X", savenames => \%nm;
ok(defined(&greet), "def greet");
is_deeply(\%nm, {greet => 1}, "no other names exported");
is(greet("world"), "hello world from X", "&greet");
}

__END__
