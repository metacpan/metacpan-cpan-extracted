# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Config;
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
    plan tests => 53, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($run_env, $ret, $testx, $test, $subdir);

#
# The following complicated dance attempts to ensure we can create
# an executable Perl script named "scriptx" on both UNIX and Win32
# systems.  We want it to be Perl since it's about the only thing
# that we can rely on in common between the systems.
#
# The UNIX side is easy; we just put our desired Perl script in
# the file name with $Config{startperl} at the top, chmod it
# executable, and away we go.
#
# For Win32, we go the route of creating a "scriptx.bat" file with
# the magic header that reads as both an NT and a Perl script.
# The hassle is that we want this .bat file to be executable
# regardless of where we are at the moment, and the only way I
# could figure out how to do this was to put the absolute path
# name to the file in the .bat file as the first argument to
# the perl.exe invocation.  This means that we have to create our
# initial running environments up front, so we know where the
# "scriptx.bat" file will end up and can put its path name in
# itself.
#
# If anyone cares to suggest an easier way to do this, I'd be
# thrilled to hear about it.
#
$My_Config{_bat} = $iswin32 ? '.bat' : '';

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

my $script = "script";
my $scriptx = "scriptx$My_Config{_bat}";

if ($iswin32) {
    my $workpath_scriptx = $run_env->workpath($scriptx);
    $My_Config{startperl} = <<EOF;
\@rem = '--*-PERL-*--';
\@rem = '
\@echo off
rem setlocal
set ARGS=
:loop
if .%1==. goto endloop
set ARGS=%ARGS% %1
shift
goto loop
:endloop
rem ***** This assumes PERL is in the PATH *****
perl.exe $workpath_scriptx %ARGS%
goto endofperl
\@rem ';
EOF
    $My_Config{endperl} = <<'EOF';
#:endofperl
EOF
    $My_Config{cwd_pkg} = 'Win32';
    $My_Config{cwd_sub} = 'Win32::GetCwd';
} else {
    $My_Config{startperl} = $Config{startperl};
    $My_Config{endperl} = '';
    $My_Config{cwd_pkg} = 'Cwd';
    $My_Config{cwd_sub} = 'cwd';
}

#
$ret = $run_env->write($script, <<EOF);
use $My_Config{cwd_pkg};
my \$cwd = $My_Config{cwd_sub}();
print STDOUT "$script:  \$string:  STDOUT:  \$cwd:  '\@ARGV'\\n";
print STDERR "$script:  \$string:  STDERR:  \$cwd:  '\@ARGV'\\n";
exit 0;
EOF
ok($ret);

$ret = $run_env->write('xxx.pm', <<EOF);
\$string = 'xxx';
EOF
ok($ret);

$ret = $run_env->write('yyy.pm', <<EOF);
\$string = 'yyy';
EOF
ok($ret);

$ret = $run_env->write($scriptx, <<EOF);
$My_Config{startperl}
use $My_Config{cwd_pkg};
my \$cwd = $My_Config{cwd_sub}();
print STDOUT "$scriptx:  \$string:  STDOUT:  \$cwd:  '\@ARGV'\\n";
print STDERR "$scriptx:  \$string:  STDERR:  \$cwd:  '\@ARGV'\\n";
exit 0;
$My_Config{endperl};
EOF
ok($ret);

$ret = chmod(0755, $scriptx) if ! $iswin32;
skip($iswin32, $ret == 1);

ok(! -x $script);
ok(-x $scriptx);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.

#
$test = Test::Cmd->new(prog => 'script', interpreter => "$^X -I$wdir -Mxxx", workdir => '', subdir => 'script_subdir');
ok($test);

$ret = $test->run();
ok($ret == 0);
ok($test->stdout eq "script:  xxx:  STDOUT:  $wdir:  ''\n");
ok($test->stderr eq "script:  xxx:  STDERR:  $wdir:  ''\n");

$ret = $test->run(args => 'arg1 arg2 arg3');
ok($ret == 0);
ok($test->stdout eq "script:  xxx:  STDOUT:  $wdir:  'arg1 arg2 arg3'\n");

# Execute "scriptx" in the middle of the run here,
# so we know it doesn't affect the $test->prog value.
# Note that it should not pick up the test environment's
# interpreter value with "-Mxxx" in it.
$ret = $test->run(prog => 'scriptx', args => 'foo');
ok($ret == 0);
ok($test->stdout eq "$scriptx:  :  STDOUT:  $wdir:  'foo'\n");
ok($test->stderr eq "$scriptx:  :  STDERR:  $wdir:  'foo'\n");

$ret = $test->run(chdir => $test->curdir, args => 'x y z');
ok($ret == 0);
ok($test->stdout eq "script:  xxx:  STDOUT:  ${\$test->workdir}:  'x y z'\n");
ok($test->stderr eq "script:  xxx:  STDERR:  ${\$test->workdir}:  'x y z'\n");

$subdir = $test->workpath('script_subdir');

$ret = $test->run(chdir => 'script_subdir');
ok($ret == 0);
ok($test->stdout eq "script:  xxx:  STDOUT:  $subdir:  ''\n");
ok($test->stderr eq "script:  xxx:  STDERR:  $subdir:  ''\n");

$ret = $test->run(chdir => 'no_subdir');
ok(! defined $ret);

$ret = $test->run(prog => 'no_script', interpreter => $^X);
ok($ret != 0);

$ret = $test->run(prog => 'script');
ok($ret != 0);

$ret = $test->run(prog => 'script', interpreter => 'no_interpreter');
ok($ret != 0);

$ret = $test->run(prog => 'no_script', interpreter => 'no_interpreter');
ok($ret != 0);

$ret = $test->run(interpreter => 'no_interpreter');
ok($ret != 0);

$ret = $test->run(interpreter => "$^X -I$wdir -Myyy", args => 'zzz');
ok($ret == 0);
ok($test->stdout eq "script:  yyy:  STDOUT:  $wdir:  'zzz'\n");
ok($test->stderr eq "script:  yyy:  STDERR:  $wdir:  'zzz'\n");

#
$testx = Test::Cmd->new(prog => 'scriptx', workdir => '', subdir => 'scriptx_subdir');
ok($testx);

$ret = $testx->run();
ok($ret == 0);
ok($testx->stdout eq "$scriptx:  :  STDOUT:  $wdir:  ''\n");
ok($testx->stderr eq "$scriptx:  :  STDERR:  $wdir:  ''\n");

$ret = $testx->run(args => 'foo bar');
ok($ret == 0);
ok($testx->stdout eq "$scriptx:  :  STDOUT:  $wdir:  'foo bar'\n");
ok($testx->stderr eq "$scriptx:  :  STDERR:  $wdir:  'foo bar'\n");

# Execute "script" in the middle of the run here,
# so we know it doesn't affect the $test->prog value.
$ret = $testx->run(prog => 'script', interpreter => "$^X -I$wdir -Mxxx", args => 'bar');
ok($ret == 0);
ok($testx->stdout eq "script:  xxx:  STDOUT:  $wdir:  'bar'\n");
ok($testx->stderr eq "script:  xxx:  STDERR:  $wdir:  'bar'\n");

$ret = $testx->run(chdir => $testx->curdir, args => 'baz');
ok($ret == 0);
ok($testx->stdout eq "$scriptx:  :  STDOUT:  ${\$testx->workdir}:  'baz'\n");
ok($testx->stderr eq "$scriptx:  :  STDERR:  ${\$testx->workdir}:  'baz'\n");

$subdir = $testx->workpath('scriptx_subdir');

$ret = $testx->run(chdir => 'scriptx_subdir');
ok($ret == 0);
ok($testx->stdout eq "$scriptx:  :  STDOUT:  $subdir:  ''\n");
ok($testx->stderr eq "$scriptx:  :  STDERR:  $subdir:  ''\n");

$ret = $testx->run(chdir => 'no_subdir');
ok(! defined $ret);

$ret = $testx->run(prog => 'no_prog');
ok($ret != 0);
