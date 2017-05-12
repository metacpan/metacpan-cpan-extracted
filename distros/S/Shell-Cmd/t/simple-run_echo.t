#!/usr/bin/perl -w

my $file  = 'simple';
my $test  = 'run_echo';

use Test::Inter;
$t = new Test::Inter "$file - $test";
$testdir = '';
$testdir = $t->testdir();

require "$testdir/script.pl";

testScript($t,$file,$test,$testdir,
           'mode'   => 'run',
           'echo'   => 'echo',
          );

#Local Variables:
#mode: cperl
#indent-tabs-mode: nil
#cperl-indent-level: 3
#cperl-continued-statement-offset: 2
#cperl-continued-brace-offset: 0
#cperl-brace-offset: 0
#cperl-brace-imaginary-offset: 0
#cperl-label-offset: 0
#End:
