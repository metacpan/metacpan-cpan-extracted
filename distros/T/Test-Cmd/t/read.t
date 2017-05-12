# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
my $iswin32;
BEGIN {
    $| = 1;
    if ($] <  5.003) {
	eval("require Win32");
	$iswin32 = ! $@;
    } else {
	$iswin32 = $^O eq "MSWin32";
    }
    plan tests => 44, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, $wdir, $wdir_file2, $wdir_foo_file1);
my @lines;

$test = Test::Cmd->new(workdir => '', subdir => 'foo');
ok($test);

$wdir = $test->workdir;
ok($wdir);
$wdir_file1 = $test->catfile($wdir, 'file1');
ok($wdir_file1);
$wdir_file2 = $test->catfile($wdir, 'file2');
ok($wdir_file2);
$wdir_foo_file3 = $test->catfile($wdir, 'foo', 'file3');
ok($wdir_foo_file3);
$wdir_foo_file4 = $test->catfile($wdir, 'foo', 'file4');
ok($wdir_foo_file4);
$wdir_foo_file5 = $test->catfile($wdir, 'foo', 'file5');
ok($wdir_foo_file5);

$ret = open(OUT, ">$wdir_file1");
ok($ret);
$ret = close(OUT);
ok($ret);

$ret = open(OUT, ">$wdir_file2");
ok($ret);
$ret = print OUT <<'_EOF_';
Test
file
#2.
_EOF_
ok($ret);
$ret = close(OUT);
ok($ret);

$ret = open(OUT, ">$wdir_foo_file3");
ok($ret);
$ret = print OUT <<'_EOF_';
Test
file
#3.
_EOF_
ok($ret);
$ret = close(OUT);
ok($ret);

$ret = open(OUT, ">$wdir_foo_file4");
ok($ret);
$ret = print OUT <<'_EOF_';
Test
file
#4.
_EOF_
ok($ret);
$ret = close(OUT);
ok($ret);

$ret = open(OUT, ">$wdir_foo_file5");
ok($ret);
$ret = print OUT <<'_EOF_';
Test
file
#5.
_EOF_
ok($ret);
$ret = close(OUT);
ok($ret);

#
$ret = $test->read(\@lines, 'no_file');
ok(! $ret);

$ret = $test->read(\$contents, 'no_file');
ok(! $ret);

$ret = $test->read(\@lines, 'file1');
ok($ret);
ok(! $lines[0]);

$ret = $test->read(\$contents, 'file1');
ok($ret);
ok(! $contents);

$ret = $test->read(\@lines, 'file2');
ok($ret);
ok(join('', @lines) eq "Test\nfile\n#2.\n");

$ret = $test->read(\$contents, 'file2');
ok($ret);
ok($contents eq "Test\nfile\n#2.\n");

$ret = $test->read(\@lines, ['foo', 'file3']);
ok($ret);
ok(join('', @lines) eq "Test\nfile\n#3.\n");

$ret = $test->read(\$contents, ['foo', 'file3']);
ok($ret);
ok($contents eq "Test\nfile\n#3.\n");

$ret = $test->read(\@lines, $wdir_foo_file4);
ok($ret);
ok(join('', @lines) eq "Test\nfile\n#4.\n");

$ret = $test->read(\$contents, $wdir_foo_file4);
ok($ret);
ok($contents eq "Test\nfile\n#4.\n");

$ret = $test->read(\@lines, [$wdir, 'foo', 'file5']);
ok($ret);
ok(join('', @lines) eq "Test\nfile\n#5.\n");

$ret = $test->read(\$contents, [$wdir, 'foo', 'file5']);
ok($ret);
ok($contents eq "Test\nfile\n#5.\n");
