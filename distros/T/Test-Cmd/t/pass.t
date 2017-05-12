# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 11, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

$here = Test::Cmd->here();
my @I_FLAGS = map(Test::Cmd->file_name_is_absolute($_) ? "-I$_" :
			"-I".Test::Cmd->catfile($here, $_), @INC);

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

my($run_env, $ret, $wdir, $test, $string);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$ret = $run_env->write('run', <<EOF);
print STDOUT "run:  STDOUT\\n";
print STDERR "run:  STDERR\\n";
exit 0;
EOF
ok($ret);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

# Everything before this was merely preparation of our "source
# directory."  Now we do some real tests.
$ret = open(PERL, "|$^X -w @I_FLAGS >perl.stdout.1 2>perl.stderr.1");
ok($ret);

$ret = print PERL <<'EOF';
use Test::Cmd;
$test = Test::Cmd->new(prog => 'run', interpreter => "$^X", workdir => '');
$test->run();
$test->pass($? == 0);
EOF
ok($ret);

$ret = close(PERL);
ok($ret);
ok($? == 0);

$string = contents("perl.stdout.1");
ok($string eq "");
$string = contents("perl.stderr.1");
ok($string eq "PASSED\n");
