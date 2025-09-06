#!perl

use strict;
use warnings;

BEGIN {
    if (eval { require tEsT::mOrE }) {
        # Yey! This is very likely to be a case-insensitive file system
        import Test::More tests => 27;
        my $f = $INC{"Test/More.pm"} = delete $INC{"tEsT/mOrE.pm"};
        ok($f, "Case-ignorant file system detected");
        ok($INC{"Test/More.pm"}, "Test::More loaded with munged case: $f");
    }
    else {
         print "1..0 # SKIP Smells like case-sensitive file system so not a valid test: $^O\n";
         exit;
    }
}

# Compile-time flagging sensitive modules
use Module::Case qw(-all);
BEGIN { ok(1, "[use Module::Case] compiled and imported with '-all' modules flagged"); }

# Load perfect case module first
ok(!$INC{"Cwd.pm"}, "Cwd not loaded yet");
ok(require Cwd, "Cwd require'd");
ok($INC{"Cwd.pm"}, "Cwd loaded correctly");

# Attempt to load bad case modules last
foreach my $bad (qw[cwd cwD cWd cWD CwD CWd CWD]) {
    ok(!eval { require "$bad.pm" }, "$bad: Correctly FAILS even on case-insensitive file system");
    chomp(my $why = $@);
    ok($why, "$bad Reason: $why");
    ok(!$INC{"$bad.pm"}, "$bad never loaded");
}
