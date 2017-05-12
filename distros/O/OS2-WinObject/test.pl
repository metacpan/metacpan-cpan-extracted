# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..15\n"; }
END {print "not ok 1\n" unless $loaded;}
use OS2::WinObject;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 1;

use OS2::WinObject ':all';

$test++;
$x = QueryObject('<WP_DESKTOP>') or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
OpenObject($x,OPEN_SETTINGS,1) or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
$buf = ' ' x 500;
QueryObjectPath($x,$buf,length($buf)) or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
$p = ObjectPath($x) or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
$buf =~ s/\0.*//s or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
$p eq $buf or print "#'$p' ne '$buf'\nnot ";
print "ok $test\n";

print "# path to desktop is '$buf'\n";

$test++;
$p1 = ActiveDesktopPathname() or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
$p eq $p1 or print "#'$p' ne '$p1'\nnot ";
print "ok $test\n";

$test++;
%x = ObjectClasses or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
$x{WPAbstract} or print "not ";
print "ok $test\n";
#print STDERR "#$_\n" for %x;

$test++;
$x{WPAbstract} =~ /\bPMWP\b/ or print "not ";
print "ok $test\n";
#print STDERR "#$_\n" for %x;

$test++;
$dt = QueryDesktopWindow or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
($x,$y,$w,$h,$fl,$b,$s) = WindowPos($dt) or print "# \$!=$!\nnot ";
print "ok $test\n";

$test++;
print "# (x $x, y $y, w $w, h $h, fl $fl, b $b, s $s) <- $dt => $$dt\n";
($w1, $h1) = map SysValue($_), qw( CXSCREEN CYSCREEN ) or print "# \$!=$!\nnot ";
print "ok $test\n";

warn "# unexpected sizes (x $x, y $y, w $w, h $h) of desktop\n"
    unless $x == 0 and $y == 0 and $w == $w1 and $h == $h1;
