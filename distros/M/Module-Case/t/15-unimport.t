#!perl

use strict;
use warnings;

BEGIN {
    if (eval { require tEsT::mOrE }) {
        # Yey! This is very likely to be a case-insensitive file system
        import Test::More tests => 40;
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
use Module::Case qw(cwd cwD cWd cWD Cwd CwD CWd);
BEGIN { ok(1, "[use Module::Case] compiled and imported with flagged modules"); }

my $why;

BEGIN {
    ok(!eval { require cwd }, "cwd: sensitive package correctly fails even on case-ignorant file system");
    chomp($why = $@);
    ok($why, "Reason: $why");
    ok(!$INC{"cwd.pm"}, "cwd never loaded");
}

BEGIN { ok($Module::Case::sensitive_modules->{cWd}, "cWd: Still flagged as case-sensitive"); }
# Compile-time removal of specific package
no Module::Case qw(cWd No::Such::Module);
BEGIN { ok(!$Module::Case::sensitive_modules->{cWd}, "[no Module::Case qw(cWd)] correctly disabled flagged package"); }


BEGIN {
    ok(!eval { require cwD }, "cwD: correctly fails even on case-ignorant file system");
    chomp($why = $@);
    ok($why, "cwD Reason: $why");
    ok(!$INC{"cwD.pm"}, "cwD never loaded");

    ok(eval { require cWd }, "cWd: Loaded incorrect decoy after compile-time disabling flagged package");
    chomp($why = $@);
    ok(!$why, "cWd Reason: $why");
    ok($INC{"cWd.pm"}, 'cWd jammed into %INC: '.$INC{"cWd.pm"});
    ok(scalar keys %Cwd::, "cWd: decoy gleefully jammed symbols into Cwd namespace");
    # Lazy way to blow away all symbols to act like it was never loaded
    %Cwd:: = ();
    ok(!scalar keys %Cwd::, "cWd: cleaned up decoy symbols namespace polution");
    delete $INC{"cWd.pm"};
    ok(!$INC{"cWd.pm"}, 'cWd: cleaned up decoy %INC polution');
}

ok(!$Module::Case::sensitive_modules->{CWD}, "CWD: Package not flagged yet");
# Run-time flagging of case-sensitive package
import Module::Case qw(CWD);
ok($Module::Case::sensitive_modules->{CWD}, "CWD: Package flagged at run-time");

ok($Module::Case::sensitive_modules->{CwD}, "CwD: Package still flagged");
# Run-time disable of case-sensitive package
my $wiped = unimport Module::Case qw(CwD No::Such::Module);
is($wiped, "CwD", "[unimport Module::Case qw(CwD No::Such::Module);] unimport returned disabled package $wiped");
ok(!$Module::Case::sensitive_modules->{CwD}, "CwD: Package unflagged at run-time");

ok(!$INC{"CWd.pm"}, "CWd not loaded yet");
ok(!eval { require CWd }, "CWd: correctly fails even on case-ignorant file system");
chomp($why = $@);
ok($why, "CWd Reason: $why");
ok(!$INC{"CWd.pm"}, "CWd never loaded");

ok(!$INC{"CWD.pm"}, "CWD not loaded yet");
ok(!eval { require CWD }, "CWD: correctly fails even on case-ignorant file system");
chomp($why = $@);
ok($why, "CWD Reason: $why");
ok(!$INC{"CWD.pm"}, "CWD never loaded");

ok(!$INC{"Cwd.pm"}, "Cwd not loaded yet");
ok(!defined &Cwd::cwd, "Cwd symbols not loaded");
ok(eval { require Cwd }, "Cwd require'd");
chomp($why = $@);
ok(!$why, "Cwd no error $why");
ok($INC{"Cwd.pm"}, "Cwd loaded correctly");
ok(defined &Cwd::cwd, "Cwd created symbols correctly");

ok(!$INC{"cWD.pm"}, "cWD not loaded yet");
ok(!eval { require cWD }, "cWD: correctly fails even on case-ignorant file system");
chomp($why = $@);
ok($why, "cWD Reason: $why");
ok(!$INC{"cWD.pm"}, "cWD never loaded");
