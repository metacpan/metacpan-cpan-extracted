# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 43, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

$here = Test::Cmd->here();
my @I_FLAGS = map(Test::Cmd->file_name_is_absolute($_) ? "-I$_" :
			"-I".Test::Cmd->catfile($here, $_), @INC);

my($run_env, $wdir, $ret, $test, $string);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$tdir1 = $run_env->workdir;
ok($tdir1);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$tdir2 = $run_env->workdir;
ok($tdir2);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$tdir3 = $run_env->workdir;
ok($tdir3);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

sub contents {
    my $file = shift;
    if (! open(FILE, $file)) {
	return undef;
    }
    my $string = join('', <FILE>);
    if (! close(FILE)) {
	return undef;
    }
    return $string;
}

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.

$ENV{PRESERVE} = '1';

$ENV{TMPDIR} = $tdir1;

$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.1 2>perl.stderr.1");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
my($test, $wdir, $ret);
$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! $test);
$wdir = $test->workdir;
$test->fail(! $wdir);
$ret = $test->write('file1', <<EOF_1);
Test file #1.
EOF_1
$test->fail(! $ret);
$test->pass;
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.1");
ok(defined $string);
ok(! $string);
$string = contents("perl.stderr.1");
ok(defined $string);
ok($string eq "PASSED\n");

$path = Test::Cmd->catfile($tdir1, '*testcmd*', 'file1');
ok(defined $path);
$path =~ s#\\#/#g;
$string = contents(eval "<$path>");
ok(defined $string);
ok($string eq "Test file #1.\n");

#
$ENV{TMPDIR} = $tdir2;

$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.2 2>perl.stderr.2");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
my($test, $wdir, $ret);
$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! $test);
$wdir = $test->workdir;
$test->fail(! $wdir);
$ret = $test->write('file2', <<EOF_1);
Test file #2.
EOF_1
$test->fail(! $ret);
$test->pass;
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.2");
ok(defined $string);
ok(! $string);
$string = contents("perl.stderr.2");
ok(defined $string);
ok($string eq "PASSED\n");

$path = Test::Cmd->catfile($tdir2, '*testcmd*', 'file2');
ok(defined $path);
$path =~ s#\\#/#g;
$string = contents(eval "<$path>");
ok(defined $string);
ok($string eq "Test file #2.\n");

#
$ENV{TMPDIR} = Test::Cmd->catfile($tdir3, '');

$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.3 2>perl.stderr.3");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
my($test, $wdir, $ret);
$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! $test);
$wdir = $test->workdir;
$test->fail(! $wdir);
$ret = $test->write('file3', <<EOF_1);
Test file #3.
EOF_1
$test->fail(! $ret);
$test->pass;
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.3");
ok(defined $string);
ok(! $string);
$string = contents("perl.stderr.3");
ok(defined $string);
ok($string eq "PASSED\n");

$path = Test::Cmd->catfile($tdir3, '*testcmd*', 'file3');
ok(defined $path);
$path =~ s#\\#/#g;
$string = contents(eval "<$path>");
ok(defined $string);
ok($string eq "Test file #3.\n");
