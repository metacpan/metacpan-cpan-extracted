# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 12, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
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
Test file #1.
EOF
ok($ret);
$ret = chdir($wdir);
ok($ret);
$ret = chmod(0444, 'file2');
ok($ret);
$ret = chmod(0555, $wdir);
ok($ret);

$test->cleanup;

ok(! -d $wdir);
