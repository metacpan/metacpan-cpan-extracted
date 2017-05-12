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
    plan tests => 22, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

use File::Spec;

my($ret, $workdir_foo, $workdir_bar, $no_such_subdir);

my $test = Test::Cmd->new;
ok($test);
ok(! $test->workdir);

$test = Test::Cmd->new(workdir => undef);
ok($test);
ok(! $test->workdir);

$test = Test::Cmd->new(workdir => '');
ok($test);
ok(File::Spec->file_name_is_absolute($test->workdir));
ok(-d $test->workdir);

$test = Test::Cmd->new(workdir => 'dir');
ok($test);
ok(File::Spec->file_name_is_absolute($test->workdir));
ok(-d $test->workdir);

$no_such_subdir = $test->catfile('no', 'such', 'subdir');

$test = Test::Cmd->new(workdir => $no_such_subdir);
ok(! $test);

$test = Test::Cmd->new(workdir => 'foo');
ok($test);
$workdir_foo = $test->workdir;
ok(File::Spec->file_name_is_absolute($workdir_foo));

$ret = $test->workdir('bar');
ok($ret);
$workdir_bar = $test->workdir;
ok(File::Spec->file_name_is_absolute($workdir_bar));

$ret = $test->workdir($no_such_subdir);
ok(! $ret);
ok($workdir_bar eq $test->workdir);

ok(-d $workdir_foo);
ok(-d $workdir_bar);

if ($iswin32) {
    eval("use Win32");
    $cwd_ref = \&Win32::GetCwd;
} else {
    eval("use Cwd");
    $cwd_ref = \&Cwd::cwd;
}

$ret = chdir($test->workdir);
ok($ret);
ok($test->workdir eq &$cwd_ref());
