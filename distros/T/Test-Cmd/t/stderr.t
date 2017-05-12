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

my($run_env, $ret, $wdir, $test);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$ret = $run_env->write('run1', <<EOF);
print STDOUT "run1 STDOUT \@ARGV\\n";
print STDOUT "run1 STDOUT second line\\n";
print STDERR "run1 STDERR \@ARGV\\n";
print STDERR "run1 STDERR second line\\n";
exit 0;
EOF
ok($ret);
$ret = $run_env->write('run2', <<EOF);
print STDOUT "run2 STDOUT \@ARGV\\n";
print STDOUT "run2 STDOUT second line\\n";
print STDERR "run2 STDERR \@ARGV\\n";
print STDERR "run2 STDERR second line\\n";
exit 0;
EOF
ok($ret);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.
$test = Test::Cmd->new(interpreter => "$^X", workdir => '');
ok($test);

ok(! defined $test->stderr);

$test->prog('run1');
$test->run('args' => 'foo bar');
ok($? == 0);
$test->prog('run2');
$test->run('args' => 'snafu');
ok($? == 0);

ok($test->stderr eq "run2 STDERR snafu\nrun2 STDERR second line\n");
ok($test->stderr(1) eq "run1 STDERR foo bar\nrun1 STDERR second line\n");
