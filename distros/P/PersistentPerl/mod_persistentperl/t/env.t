#
# Test for two bugs:
#
# mod_persistentperl mixes up the perperl options on the #! line in the script
#
# mod_persistentperl can't switch tempbase between scripts because it holds open
# the tempfile.


use lib 't';
use ModTest;

my $scr = 'perperl/env';

ModTest::test_init(5, [$scr], '
    SetEnv	"ENVTEST" "XXX"
');

print "1..1\n";
my $txt = &ModTest::html_get("/$scr");
if ($txt =~ /ENVTEST=XXX/) {
    print "ok\n";
} else {
    print "not ok\n";
}
