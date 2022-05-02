use strict;
use warnings;
use Cwd;
use Test::More;
use Test::Requires 'Test::Strict';

$Test::Strict::TEST_SYNTAX = 1;
$Test::Strict::TEST_STRICT = 1;
$Test::Strict::TEST_WARNINGS = 1;
$Test::Strict::TEST_SKIP = [
    # git places some Perl scripts here
    glob(getcwd()."/t/../.git/hooks/*"),
    # Perl tainted mode does not work with Test::Strict
    getcwd()."/t/../script/ospfview.cgi",
    getcwd()."/t/../blib/script/ospfview.cgi",
    # try different paths for CPAN testers
    getcwd()."/script/ospfview.cgi",
    getcwd()."/blib/script/ospfview.cgi",
    getcwd()."\\script\\ospfview.cgi",
    getcwd()."\\blib\\script\\ospfview.cgi",
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
diag(getcwd());
diag("_all_perl_files:");
diag($_) foreach Test::Strict::_all_perl_files();

all_perl_files_ok();
