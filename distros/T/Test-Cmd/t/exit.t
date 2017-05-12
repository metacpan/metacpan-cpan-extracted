# Copyright 1999-2001 Steven Knight.  All rights reserved.  This program
# is free software; you can redistribute it and/or modify it under the
# same terms as Perl itself.

######################### We start with some black magic to print on failure.

use Test;
BEGIN { $| = 1; plan tests => 19, onfail => sub { $? = 1 if $ENV{AEGIS_TEST} } }
END {print "not ok 1\n" unless $loaded;}
use Test::Cmd;
$loaded = 1;
ok(1);

######################### End of black magic.

$here = Test::Cmd->here();
my @I_FLAGS = map(Test::Cmd->file_name_is_absolute($_) ? "-I$_" :
			"-I".Test::Cmd->catfile($here, $_), @INC);

my($run_env, $wdir, $ret, $test, $wd, $string);

$run_env = Test::Cmd->new(workdir => '');
ok($run_env);
$wdir = $run_env->workdir;
ok($wdir);
$ret = chdir($wdir);
ok($ret);

# Everything before this was merely preparation of our "source directory."

my @cleanup;

END {
    foreach my $dir (@cleanup) {
	rmdir $dir if -d $dir;
    }
}

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

sub test_it {
    my($condition, $preserved) = @_;

    my %close_true = (
	'pass'		=> 1,
	'fail'		=> 0,
	'no_result'	=> 0,
    );

    my %exit_status = (
	'pass'		=> 0,
	'fail'		=> 1,
	'no_result'	=> 2,
    );

    my %result_string = (
	'pass'		=> "PASSED\n",
	'fail'		=> "FAILED test at line 5 of -.\n",
	'no_result'	=> "NO RESULT for test at line 5 of -.\n",
    );

    if (! open(PERL, "|$^X @I_FLAGS >perl.stdout 2>perl.stderr")) {
	print STDOUT "# Could not open $^X: $!\n";
	return undef;
    }


    my $ret = print PERL <<EOF;
use Test::Cmd;
\$test = Test::Cmd->new(workdir => '');
Test::Cmd->fail(! \$test);
print STDOUT \$test->workdir;
\$test->$condition;
EOF
    if (! $ret) {
	print STDOUT "# Could not write to $^X: $!\n";
	return undef;
    }

    $ret = close(PERL);
    if ($close_true{$condition} ? ! $ret : $ret) {
	print STDOUT "# Unexpected return from close(): $!\n";
	$wd = contents("perl.stdout");
	push @cleanup, $wd if defined $wd;
	return undef;
    }

    if (($?>>8) != $exit_status{$condition}) {
	print STDOUT "# Expected exit status ", $exit_status{$condition}, " got ", $?>>8, "\n";
	$wd = contents("perl.stdout");
	push @cleanup, $wd if defined $wd;
	return undef;
    }

    $wd = contents("perl.stdout");
    if (! defined $wd) {
	print STDOUT "# no working directory path name on standard output\n";
	return undef;
    }
    push @cleanup, $wd;

    $string = contents("perl.stderr");
    if ($string ne $result_string{$condition}) {
	print STDOUT "# Expected error output:\n";
	print STDOUT "# ", $result_string{$condition};
	print STDOUT "# Got error output:\n";
	print STDOUT "# ", $string;
	return undef;
    }

    return ($preserved ? -d $wd : ! -d $wd);
}

delete $ENV{PRESERVE};
delete $ENV{PRESERVE_PASS};
delete $ENV{PRESERVE_FAIL};
delete $ENV{PRESERVE_NO_RESULT};

$ret = test_it('pass', 0);
ok($ret);
$ret = test_it('fail', 0);
ok($ret);
$ret = test_it('no_result', 0);
ok($ret);

$ENV{PRESERVE} = '1';
delete $ENV{PRESERVE_PASS};
delete $ENV{PRESERVE_FAIL};
delete $ENV{PRESERVE_NO_RESULT};

$ret = test_it('pass', 1);
ok($ret);
$ret = test_it('fail', 1);
ok($ret);
$ret = test_it('no_result', 1);
ok($ret);

delete $ENV{PRESERVE};
$ENV{PRESERVE_PASS} = '1';
delete $ENV{PRESERVE_FAIL};
delete $ENV{PRESERVE_NO_RESULT};

$ret = test_it('pass', 1);
ok($ret);
$ret = test_it('fail', 0);
ok($ret);
$ret = test_it('no_result', 0);
ok($ret);

delete $ENV{PRESERVE};
delete $ENV{PRESERVE_PASS};
$ENV{PRESERVE_FAIL} = '1';
delete $ENV{PRESERVE_NO_RESULT};

$ret = test_it('pass', 0);
ok($ret);
$ret = test_it('fail', 1);
ok($ret);
$ret = test_it('no_result', 0);
ok($ret);

delete $ENV{PRESERVE};
delete $ENV{PRESERVE_PASS};
delete $ENV{PRESERVE_FAIL};
$ENV{PRESERVE_NO_RESULT} = '1';

$ret = test_it('pass', 0);
ok($ret);
$ret = test_it('fail', 0);
ok($ret);
$ret = test_it('no_result', 1);
ok($ret);
