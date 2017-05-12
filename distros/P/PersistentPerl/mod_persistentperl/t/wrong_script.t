#
# Bug in mod_persistentperl in release 2.10.  If two scripts are run
# by the same httpd within 5 seconds, the first script will be executed
# instead of the second.  We're caching the stat of the script when
# we shouldn't.
#

use lib 't';
use ModTest;

my $scr = 'perperl/script';

ModTest::test_init(5, [map {"$scr$_"} (1,2)]);

print "1..1\n";

sub runit { my $which = shift;
    &ModTest::html_get("/$scr$which");
}

my $one = &runit(1);
my $two = &runit(2);

## print STDERR "one=$one two=$two\n";

if ($one == 1 && $two == 2) {
    print "ok\n";
} else {
    print "not ok\n";
}
