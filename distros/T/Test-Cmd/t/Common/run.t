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
    plan tests => 31, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
}
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($test, $ret, $wdir);

$test = Test::Cmd->new(workdir => '');

$perl = $^X;
@path_dirs = split(/$Config{path_sep}/, $ENV{PATH});
while (! -x $perl) {
    $dir = shift @path_dirs;
    if (! $dir) {
	print "# Can not find executable $^X on PATH\n";
	print "# ($ENV{PATH}\n";
	exit (1);
    }
    $perl = Test::Cmd->catfile($dir, $^X);
}
if (! Test::Cmd->file_name_is_absolute($perl)) {
    use Cwd;
    $perl = Test::Cmd->catfile(Cwd::cwd(), $perl);
}

$flags = "-I " . join(" -I ", @INC);

$pass = $test->workpath('pass');
$fail = $test->workpath('fail');
$stdout = $test->workpath('stdout');
$stderr = $test->workpath('stderr');

$test->write($pass, <<'_EOF_');
open(OUT, '>output');
print OUT "pass: @ARGV\n";
close(OUT);
exit(0);
_EOF_

$test->write($fail, <<'_EOF_');
open(OUT, '>output');
print OUT "fail: @ARGV\n";
close(OUT);
exit(1);
_EOF_

$test->write($stdout, <<'_EOF_');
print STDOUT "stdout: @ARGV\n";
exit(0);
_EOF_

$test->write($stderr, <<'_EOF_');
print STDERR "stderr: @ARGV\n";
exit(0);
_EOF_

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$pass', interpreter => '$perl', workdir => '');
\$t->run();
\$t->file_matches('output', "pass: \n");
\$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$pass', interpreter => '$perl', workdir => '');
\$t->run(args => 'one two three');
\$t->file_matches('output', "pass: one two three\n");
\$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$fail', interpreter => '$perl', workdir => '');
\$t->run();
\$t->pass;
EOF
ok(($ret >> 8) == 1);
ok($test->stdout eq "");
ok($test->stderr =~ /FAILED test of fail/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$pass', interpreter => '$perl', workdir => '');
\$t->run(fail => '$? != 1');
\$t->pass;
EOF
ok(($ret >> 8) == 1);
ok($test->stdout eq "");
ok($test->stderr =~ /FAILED test of pass/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$stdout', interpreter => '$perl', workdir => '');
\$t->run(stdout => "stdout: \n");
\$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$stdout', interpreter => '$perl', workdir => '');
\$t->run(args => 'foo', stdout => "stdout: \n");
\$t->pass;
EOF
ok(($ret >> 8) == 1);
ok($test->stdout eq "");
ok($test->stderr =~ /diff expected vs. actual contents of STDOUT.*FAILED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$stderr', interpreter => '$perl', workdir => '');
\$t->run();
\$t->pass;
EOF
ok(($ret >> 8) == 1);
ok($test->stdout eq "");
ok($test->stderr =~ /diff expected vs. actual contents of STDERR.*FAILED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$stderr', interpreter => '$perl', workdir => '');
\$t->run(stderr => undef);
\$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$stderr', interpreter => '$perl', workdir => '');
\$t->run(stderr => "stderr: \n");
\$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<EOF);
use Test::Cmd::Common;
\$t = Test::Cmd::Common->new(prog => '$stderr', interpreter => '$perl', workdir => '');
\$t->run(args => 'foo', stderr => "stderr: \n");
\$t->pass;
EOF
ok(($ret >> 8) == 1);
ok($test->stdout eq "");
ok($test->stderr =~ /diff expected vs. actual contents of STDERR.*FAILED/ms);
