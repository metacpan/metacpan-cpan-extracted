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

output num     command all          => 2 2

output num     command fail         => 2


output exit    command all          => 0 10

output exit    command fail         => 10


output command command all          =>
   [ '$tdir/bin/fail_on_2 \$i' ]
   [ '$tdir/bin/fail_on_2 \$i' ]

output command command fail         =>
   [ '$tdir/bin/fail_on_2 \$i' ]


output stdout  command all          =>
   [ "fail_on_2 succeeds on 1" ]
   [ "fail_on_2 fails on 2" ]

output stdout  command fail         =>
   [ "fail_on_2 fails on 2" ]


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
