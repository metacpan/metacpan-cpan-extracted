#!/usr/bin/perl -w

my $script = 'alt_retry';
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

output num     command all          => 1 2 3 4

output exit    command all          => 0 0 0 0

output command command all          =>
   [ '$tdir/bin/succ 1' ]
   [ 'rm -f $tdir/fail_twice.*.flag' ]
   [ '$tdir/bin/fail_twice $tdir' '$tdir/bin/fail 2' ]
   [ '$tdir/bin/succ 3' ]

output stdout  command all          =>
   [ "This is the 'succ' command stdout with argument: 1" ]
   []
   [ "fail_twice running first time"
     "This is the 'fail' command stdout with argument: 2"
     "fail_twice running second time"
     "This is the 'fail' command stdout with argument: 2"
     "fail_twice running third time" ]
   [ "This is the 'succ' command stdout with argument: 3" ]


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
