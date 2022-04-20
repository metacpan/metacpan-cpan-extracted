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
    # different path for CPAN testers on Windows
    getcwd()."\\script\\ospfview.cgi",
    getcwd()."\\blib\\script\\ospfview.cgi",
];

all_perl_files_ok();
