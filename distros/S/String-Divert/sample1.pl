
use lib "./blib/lib";

use String::Divert;

#   standard object-oriented API (SAPI)
$x = new String::Divert;
$x->assign("foo");
$x->fold("sub");
$x->append("quux");
$x->divert("sub");
$x->append("bar");
$x->undivert(0);
print "x=".$x->string()."\n";
$x->destroy();

#   extended operator-overloaded API (XAPI)
$x = new String::Divert;
$x->overload(1);
$x .= "foo";
$x *= "sub";
$x .= "quux";
$x >> "sub";
$x .= "bar";
$x << 0;
print "x=$x\n";
undef $x;

