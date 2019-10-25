#!perl
use strict;
use warnings;

use Shell::Run;
use Test2::V0;
use Test2::Tools::Class;

my $output;
my $rc;

my $bash = Shell::Run->new(name => 'bash');
isa_ok($bash, ['Shell::Run'], 'got blessed object');

# run test
$rc = $bash->run('echo hello', $output);
is $output, "hello\n", 'capture output';
is $rc, T(), 'retcode ok';

# get status code on success
my $sc;
($sc, $rc) = $bash->run('exit');
is $sc, 0, 'status code 0';
is $rc, T(), 'return code true';

# get status code on failure
($sc, $rc) = $bash->run('exit 2');
is $sc, 2, 'status code 2';
is $rc, F(), 'return code false';

done_testing;
