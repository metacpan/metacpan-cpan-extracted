use strict;
use warnings;
use Cwd;
use Test::More;
use Test::Requires 'Test::Strict';

my $cwd = getcwd();
(my $wincwd = $cwd) =~ s,/,\\,g;

$Test::Strict::TEST_SYNTAX = 1;
$Test::Strict::TEST_STRICT = 1;
$Test::Strict::TEST_WARNINGS = 1;
$Test::Strict::TEST_SKIP = [
    # git places some Perl scripts here
    glob(getcwd()."/t/../.git/hooks/*"),
    # Perl tainted mode does not work with Test::Strict
    "$cwd/t/../script/ospfview.cgi",
    "$cwd/t/../blib/script/ospfview.cgi",
    # try different paths for CPAN testers
    "$wincwd\\t\\..\\script\\ospfview.cgi",
    "$wincwd\\t\\..\\blib\\script\\ospfview.cgi",
    "$cwd/script/ospfview.cgi",
    "$cwd/blib/script/ospfview.cgi",
    "$wincwd\\script\\ospfview.cgi",
    "$wincwd\\blib\\script\\ospfview.cgi",
    "t/../script/ospfview.cgi",
    "t/..blib/script/ospfview.cgi",
    "t\\..\\script\\ospfview.cgi",
    "t\\..\\blib\\script\\ospfview.cgi",
    "script/ospfview.cgi",
    "blib/script/ospfview.cgi",
    "script\\ospfview.cgi",
    "blib\\script\\ospfview.cgi",
];

# show which paths are used, so CPAN testers can be fixed
diag("getcwd:");
diag($cwd);
diag("wincwd:");
diag($wincwd);
diag("_all_perl_files:");
diag($_) foreach Test::Strict::_all_perl_files();

all_perl_files_ok();
