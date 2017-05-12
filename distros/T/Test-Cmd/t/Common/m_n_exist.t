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
    plan tests => 7, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} }
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
$t = Test::Cmd::Common->new(workdir => '');
$t->must_not_exist('file1');
$t->pass;
EOF
ok($ret == 0);
ok($test->stdout eq "");
ok($test->stderr =~ /PASSED/ms);

$ret = $test->run(prog => "$perl $flags", stdin => <<'EOF');
use Test::Cmd::Common;
$t = Test::Cmd::Common->new(workdir => '');
$t->write('file1', "file1\n");
$t->must_not_exist('file1');
$t->pass;
EOF
ok(($ret >> 8) == 1);
ok($test->stdout eq "");
ok($test->stderr =~ /unexpected files exist: file1\nFAILED/ms);
