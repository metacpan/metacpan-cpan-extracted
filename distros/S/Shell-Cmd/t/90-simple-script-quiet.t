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
                    'output' => 'quiet',
                    'tmp_script_keep' => 0,
                   );

my $tests = <<"EOT";

output num     command all          => 1 2

output num     command curr         => 1

output num     command next         => 2

output num     command 1            => 1

output num     command fail         =>


output label   command all          => Succ1 Succ2

output label   command curr         => Succ2

output label   command 1            => Succ1

output label   command fail         =>


output exit    command all          => 0 0

output exit    command curr         => 0

output exit    command 1            => 0

output exit    command fail         =>


output command command all          =>
   [ '$tdir/bin/succ 1 warn' ]
   [ '$tdir/bin/succ 2 warn' ]

output command command curr         =>
   [ '$tdir/bin/succ 2 warn' ]

output command command 1            =>
   [ '$tdir/bin/succ 1 warn' ]

output command command fail         =>


output stdout  command all          =>
   [ ]
   [ ]

output stdout  command curr         =>
   [ ]

output stdout  command 1            =>
   [ ]

output stdout  command fail         =>


output stderr  command all          =>

output stderr  command curr         =>

output stderr  command 1            =>

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
