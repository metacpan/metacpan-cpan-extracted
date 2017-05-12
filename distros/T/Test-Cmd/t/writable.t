# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 30, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, $wdir);

$test = Test::Cmd->new(workdir => '', subdir => 'foo');
ok($test);
$ret = $test->write('file1', <<EOF);
Test file #1.
EOF
ok($ret);
$ret = $test->write(['foo', 'file2'], <<EOF);
Test file #2.
EOF
ok($ret);
$wdir = $test->workdir;
ok($wdir);

$ret = chdir($wdir);
ok($ret);

ok(-w $test->curdir);
ok(-w 'file1');
ok(-w 'foo');
ok(-w $test->workpath('foo', 'file2'));

$ret = $test->writable($wdir, 0);
ok($ret == 0);

# If we're running as root, then non-writability tests fail because root
# can write to anything.  Let them know why we're skipping those tests.
print "# Skipping tests because you're running with EUID of 0\n" if $> == 0;
skip($> == 0, ! -w $test->curdir);
skip($> == 0, ! -w 'file1');
skip($> == 0, ! -w 'foo');
skip($> == 0, ! -w $test->workpath('foo', 'file2'));

$ret = $test->writable($wdir, 1);
ok($ret == 0);
ok(-w $test->curdir);
ok(-w 'file1');
ok(-w 'foo');
ok(-w $test->workpath('foo', 'file2'));

# Make sure we can call with the optional error-collecting hash.
# It would be good to check that this does, in fact, collect errors,
# but the only two ways I can think of to get chmod() to generate an
# error are a non-existent file (which won't happen because
# finddepth() only calls its routine for existing files) or a file
# owned by someone else.  We can't rely on being able to chown()
# a file unless we're root, though, and if we're root, the file will
# be writable because root can write to anything.  So just punt on
# this for now.
my %errs;
$ret = $test->writable($wdir, 0, \%errs);
ok($ret == 0);

skip($> == 0, ! -w $test->curdir);
skip($> == 0, ! -w 'file1');
skip($> == 0, ! -w 'foo');
skip($> == 0, ! -w $test->workpath('foo', 'file2'));

$ret = $test->writable($wdir);
ok($ret == 0);
ok(-w $test->curdir);
ok(-w 'file1');
ok(-w 'foo');
ok(-w $test->workpath('foo', 'file2'));
