# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 9, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

my($run_env, $ret, $wdir, $test);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$ret = $run_env->write('run1', <<EOF);
print STDOUT "run1 STDOUT\\n";
print STDERR "run1 STDERR\\n";
exit 0;
EOF
ok($ret);
$ret = $run_env->write('run2', <<EOF);
print STDOUT "run2 STDOUT\\n";
print STDERR "run2 STDERR\\n";
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

$test->prog('run1');
$test->run();
ok($? == 0);
$test->prog('run2');
$test->run();
ok($? == 0);
