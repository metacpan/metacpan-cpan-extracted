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
    plan tests => 21, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, $wdir);

$test = Test::Cmd->new(workdir => '', subdir => ['no', 'such', 'subdir']);
ok(! $test);

$test = Test::Cmd->new(workdir => '', subdir => 'foo');
ok($test);
$ret = $test->subdir('bar');
ok($ret == 1);
$wdir = $test->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

$ret = $test->subdir([qw(foo succeed)]);
ok($ret == 1);

# I don't understand why, but setting read-only on a Windows NT
# directory on Windows NT still allows you to create a file.
# That doesn't make sense to my UNIX-centric brain, but it does
# mean we need to skip the related tests on Win32 platforms.
$ret = chmod(0500, 'foo');
skip($iswin32, $ret == 1);
$ret = $test->subdir([qw(foo fail)]);
skip($iswin32 || $> == 0, ! $ret);

$ret = $test->subdir([qw(sub dir ectory)], 'sub');
ok($ret == 1);

$ret = $test->subdir('one', ['one', 'two'], [qw(one two three)]);
ok($ret == 3);

$ret = $test->subdir([$wdir, 'a'], [$wdir, 'a', 'b']);
ok($ret == 2);

ok(-d 'foo');
ok(-d 'bar');
ok(-d $test->workpath('foo', 'succeed'));
skip($iswin32 || $> == 0, ! -d $test->workpath('foo', 'fail'));
ok( -d 'sub');
ok(! -d $test->workpath(qw(sub dir)));
ok(! -d $test->workpath(qw(sub dir ectory)));
ok(-d $test->workpath(qw(one two three)));
ok(-d $test->workpath(qw(a b)));
