use warnings; use strict;
use Test::More tests => 14;

use Object::Import ();

{
package X;
sub greet { 
	my($o, $a) = @_; 
	"hello $a from $o"; 
}
}

{
package G1;
use Test::More;
our %nm;
import Object::Import "Object::Import", list => ["import"], prefix => "object_";
ok(defined(&object_import), "object_import exported G1");
object_import("X", savenames => \%nm, target => "G1");
ok(defined(&greet), "def greet G1");
is_deeply(\%nm, {greet => 1}, "no other names exported G1");
is(greet("world"), "hello world from X", "&greet G1");
}

{
package G2;
use Test::More;
our %nm;
import Object::Import "Object::Import", list => ["import"], prefix => "subject_";
ok(defined(&subject_import), "subject_import exported G2");
subject_import("Object::Import", list => ["import"], prefix => "object_", target => "G2");
ok(defined(&object_import), "object_import exported G2");
object_import("X", savenames => \%nm, target => "G2");
ok(defined(&greet), "def greet G2");
is_deeply(\%nm, {greet => 1}, "no other names exported G2");
is(greet("world"), "hello world from X", "&greet G2");
}

eval q{
{
package G3;
use Test::More;
our %nm;
use Object::Import "Object::Import", list => ["import"], prefix => "object_";
ok(defined(&object_import), "object_import exported G3");
object_import "X", savenames => \%nm, target => "G3";
ok(defined(&greet), "def greet G3");
is_deeply(\%nm, {greet => 1}, "no other names exported G3");
is(greet("world"), "hello world from X", "&greet Gb");
}
};
my $eval_err = $@;
is($eval_err, "", "eval ran fine");

__END__
