#!/usr/bin/perl -w

my $script = 'fail';
my $test   = $0;
$test      =~ s,.*/,,;

use Test::Inter;
$t = new Test::Inter "$test";
$testdir = $t->testdir();

require "$testdir/script.pl";

my $tdir=`cd $testdir; pwd`;
chomp($tdir);

$::obj = '';
$::obj = testScript($t,$script,$test,$testdir,
                    'mode'   => 'script',
                   );

my $tests = <<"EOT";

output num     command all          => 1 2

output num     command fail         => 2


output label   command all          => Succ1 Fail1

output label   command fail         => Fail1


output exit    command all          => 0 10

output exit    command fail         => 10


output command command all          =>
   [ '$tdir/bin/succ 1 warn' ]
   [ '$tdir/bin/fail 1 warn' ]

output command command fail         =>
   [ '$tdir/bin/fail 1 warn' ]


output stdout  command all          =>
   [ "This is the 'succ' command stdout with argument: 1" ]
   [ "This is the 'fail' command stdout with argument: 1" ]

output stdout  command fail         =>
   [ "This is the 'fail' command stdout with argument: 1" ]


EOT

$t->tests(func  => \&testScriptMode,
          tests => $tests);
$t->done_testing();

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
