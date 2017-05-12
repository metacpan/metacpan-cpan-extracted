#!/usr/bin/perl -w

my $file  = 'simple';
my $test  = 'script=script';

use Test::Inter;
$t = new Test::Inter "$file - $test";
$testdir = '';
$testdir = $t->testdir();

require "$testdir/script.pl";

testScript($t,$file,$test,$testdir,
           'mode'   => 'dry-run',
           'script' => 'script',
           'dire'   => '/tmp',
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
