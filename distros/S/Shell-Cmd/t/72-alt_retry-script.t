#!/usr/bin/perl

use warnings;
use strict;
use Test::Inter;
$::ti = '';
$::ti = new Test::Inter $0;
require "script.pl";

my $tdir = $::ti->testdir();
$tdir = `cd $tdir; pwd`;
chomp($tdir);

$::obj = '';
$::obj = testScript(
                    'mode'   => 'script',
                   );

my $tests = <<"EOT";

output num     command all          => 1 2 3 4

output num     command curr         => 1

output num     command next         => 2

output num     command 1            => 1

output num     command fail         =>


output label   command all          => __undef__ __undef__ __undef__ __undef__


output exit    command all          => 0 0 0 0

output exit    command curr         => 0

output exit    command 1            => 0

output exit    command fail         =>


output command command all          =>
   [ '$tdir/bin/succ 1' ]
   [ 'rm -f $tdir/fail_twice.*.flag; echo "Removing fail flags"' ]
   [ '$tdir/bin/fail_twice $tdir'  '$tdir/bin/fail 2' ]
   [ '$tdir/bin/succ 3' ]

output command command 1            =>
   [ '$tdir/bin/succ 1' ]

output command command fail         =>


output stdout  command all          =>
   [ "This is the 'succ' command stdout with argument: 1" ]
   [ 'Removing fail flags' ]
   [ 'fail_twice running first time'
     "This is the 'fail' command stdout with argument: 2"
     'fail_twice running second time'
     "This is the 'fail' command stdout with argument: 2"
     'fail_twice running third time' ]
   [ "This is the 'succ' command stdout with argument: 3" ]

output stdout  command 1            =>
   [ "This is the 'succ' command stdout with argument: 1" ]

output stdout  command fail         =>


output stderr  command all          =>
   [ ]
   [ ]
   [ 'fail_twice failing first time' 'fail_twice failing second time' ]
   [ ]

output stderr  command 1            =>
   [ ]

output stderr  command fail         =>

EOT

$::ti->tests(func  => \&testScriptMode,
             tests => $tests);
$::ti->done_testing();

1;

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
