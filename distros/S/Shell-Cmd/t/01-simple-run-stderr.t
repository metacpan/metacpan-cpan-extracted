#!/usr/bin/perl -w

my $script = 'simple';
my $test   = $0;
$test      =~ s,.*/,,;

use Test::Inter;
$t = new Test::Inter "$test";
$testdir = $t->testdir();

require "$testdir/script.pl";

testScript($t,$script,$test,$testdir,
           'mode'   => 'run',
           'dire'   => '/tmp',
           'output' => 'stderr',
           'env'    => [ qw(SC_VAR_1  val_1   SC_VAR_2  val_2) ],
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
