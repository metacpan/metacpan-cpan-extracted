# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 21, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $wdir, $ret);

$test = Test::Cmd->new(workdir => '');
ok($test);
$wdir = $test->workdir;
ok($wdir);
$ret = $test->write('file1', <<EOF);
Test file #1.
EOF
ok($ret);
$test->cleanup;
ok(! -d $wdir);

$test = Test::Cmd->new(workdir => '');
ok($test);
$wdir = $test->workdir;
ok($wdir);
$ret = $test->write('file2', <<EOF);
Test file #2.
EOF
ok($ret);
$test->preserve('pass');
$test->cleanup('pass');
ok (-d $wdir);
$test->cleanup('fail');

ok (! -d $wdir);

$test = Test::Cmd->new(workdir => '');
ok($test);
$wdir = $test->workdir;
ok($wdir);
$ret = $test->write('file3', <<EOF);
Test file #3.
EOF
ok($ret);
$test->preserve('fail');
$test->cleanup('fail');

ok (-d $wdir);
$test->cleanup('pass');
ok (! -d $wdir);

$test = Test::Cmd->new(workdir => '');
ok($test);
$wdir = $test->workdir;
ok($wdir);
$ret = $test->write('file3', <<EOF);
Test file #3.
EOF
ok($ret);
$test->preserve('fail', 'no_result');
$test->cleanup('fail');

ok (-d $wdir);
$test->cleanup('no_result');
ok (-d $wdir);
$test->cleanup('pass');
ok (! -d $wdir);
