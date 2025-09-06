#!perl

use strict;
use warnings;

BEGIN {
    if (eval { require tEsT::mOrE }) {
        # Yey! This is very likely to be a case-insensitive file system
        import Test::More tests => 14;
        my $f = $INC{"Test/More.pm"} = delete $INC{"tEsT/mOrE.pm"};
        ok($f, "Case-ignorant file system detected");
        ok($INC{"Test/More.pm"}, "Test::More loaded with munged case: $f");
    }
    else {
         print "1..0 # SKIP Smells like case-sensitive file system so not a valid test: $^O\n";
         exit;
    }
}

# This is what happens WITHOUT using Module::Case at all.
# Exploit the problem on case insensitive file system:
ok(eval {require cWd}, "cWd: Case-ignorant file system gleefully loads the module");
ok(!$@, "cWd: No errors even though mismatching package $@");
ok($INC{"cWd.pm"}, 'cWd: Ugly setting jammed into %INC '.$INC{"cWd.pm"});
ok(eval {import cWd; 1}, "cWd: import didn't crash");
ok(!defined &cwd, "cWd: import didn't actually do anything");
ok(defined &Cwd::cwd, "cWd: Module actually defined the subroutines");
ok(eval {import Cwd; 1}, "Cwd: import didn't crash");
ok(defined &cwd, "Cwd: import functioned properly");

ok(eval {require iO::sOcKeT}, "iO::sOcKeT: Case-ignorant file system gleefully loads the module");
ok(!$@, "iO::sOcKeT: No errors even though mismatching package $@");
ok($INC{"iO/sOcKeT.pm"}, 'iO::sOcKeT: Ugly setting jammed into %INC '.$INC{"iO/sOcKeT.pm"});
ok(defined &IO::Socket::new, "iO::sOcKeT: Module actually defined the subroutines");
