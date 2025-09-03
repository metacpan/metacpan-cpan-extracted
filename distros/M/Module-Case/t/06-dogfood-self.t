#!perl

use strict;
use warnings;

BEGIN {
    if (eval { require tEsT::mOrE }) {
        # Yey! This is very likely to be a case-insensitive file system
        import Test::More tests => 9;
        my $f = $INC{"Test/More.pm"} = delete $INC{"tEsT/mOrE.pm"};
        ok($f, "Case-ignorant file system detected");
        ok($INC{"Test/More.pm"}, "Test::More loaded with munged case: $f");
    }
    else {
         print "1..0 # SKIP Smells like case-sensitive file system so not a valid test: $^O\n";
         exit;
    }
}

our $why = "";

# First load the real module
use Module::Case qw(Module::Case mOdUlE::cAsE);
ok($INC{"Module/Case.pm"}, "Module::Case compiled and flagged itself: ".$INC{"Module/Case.pm"});

# Test reloading again
delete $INC{"Module/Case.pm"};
ok(!$INC{"Module/Case.pm"}, "Module::Case pretend unloaded");

# Try reloading
ok(eval {require Module::Case}, "Module::Case loads itself fine");
ok($INC{"Module/Case.pm"}, 'Module::Case jammed into %INC '.$INC{"Module/Case.pm"});

# Then try loading with broken case
ok(!eval {require mOdUlE::cAsE}, "mOdUlE::cAsE fails to load itself with wrongly case");
chomp($why = $@);
ok($why, "mOdUlE::cAsE Reason: $why");
ok(!$INC{"mOdUlE/cAsE.pm"}, 'mOdUlE::cAsE not jammed into %INC');
