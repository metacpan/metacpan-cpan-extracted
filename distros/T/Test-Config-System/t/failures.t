#!perl -T
use warnings;
use strict;

eval "use Test::Builder::Tester tests => 6;";
if ($@) {
    print "1..0 # Skipped: Test::Builder::Tester not installed";
    exit;
}

### Test failure conditions
use Test::Config::System;

use File::Temp qw/ tempfile tempdir /;

my $dir = tempdir();
my ($fh, $filename) = tempfile();

my $test1 = "check_file_contents(bogus, fail)";
my $test2 = "check_file_contents(fail)";

my $test3 = "check_dir(notadir,fail)";
my $test4 = "check_dir(badmode,fail)";

my $test5 = "check_file(notafile,fail)";
my $test6 = "check_file(badmode,fail)";

test_out("not ok 1 - $test1");
test_fail(+1);
check_file_contents('/bogus/file/-/aoeu', qr//, $test1);
test_test($test1);

test_out("not ok 1 - $test2");
test_fail(+1);
check_file_contents('lib/Test/Config/System.pm', qr/$ ^/, $test2);
test_test($test2);

test_out("not ok 1 - $test3");
test_fail(+1);
check_dir('aoeu', { '-mode' => 0777 }, $test3);
test_test($test3);

test_out("not ok 1 - $test4");
test_fail(+1);
check_dir($dir, { '-mode' => 1234 }, $test4);
test_test(name => $test4, skip_err => 1 );

test_out("not ok 1 - $test5");
test_fail(+1);
check_file('aoeu', { '-mode' => 0777 }, $test5);
test_test($test5);

test_out("not ok 1 - $test6");
test_fail(+1);
check_file($filename, { '-mode' => 1234 }, $test6);
test_test(name => $test6, skip_err => 1 );


