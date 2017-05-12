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
    plan tests => 13, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
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

$ret = $test->run(prog => "$perl $flags", stdin => <<'EOF');
use Test::Cmd::Common;
$t = Test::Cmd::Common->new(workdir => '', subdir => ['no', 'such', 'subdir']);
$t->pass;
EOF
ok(($ret >> 8) == 2);
ok($test->stdout eq "");
ok($test->stderr =~ /could not create subdirectories:.*NO RESULT/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<'EOF');
use Test::Cmd::Common;
$t = Test::Cmd::Common->new(workdir => '');
$t->subdir(['no', 'such', 'subdir']);
$t->pass;
EOF
ok(($ret >> 8) == 2);
ok($test->stdout eq "");
ok($test->stderr =~ /could not create subdirectories:.*NO RESULT/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<'EOF');
use Test::Cmd::Common;
$t = Test::Cmd::Common->new(workdir => '', subdir => 'foo');
$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<'EOF');
use Test::Cmd::Common;
$t = Test::Cmd::Common->new(workdir => '');
$t->subdir(subdir => 'foo');
$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);
