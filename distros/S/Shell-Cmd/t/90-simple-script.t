#!/usr/bin/perl -w

my $script = 'simple';
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
   [ "This is the 'succ' command stdout with argument: 1" ]
   [ "This is the 'succ' command stdout with argument: 2" ]

output stdout  command curr         =>
   [ "This is the 'succ' command stdout with argument: 2" ]

output stdout  command 1            =>
   [ "This is the 'succ' command stdout with argument: 1" ]

output stdout  command fail         =>


output stderr  command all          =>
   [ "This is the 'succ' command stderr with argument: 1" ]
   [ "This is the 'succ' command stderr with argument: 2" ]

output stderr  command curr         =>
   [ "This is the 'succ' command stderr with argument: 2" ]

output stderr  command 1            =>
   [ "This is the 'succ' command stderr with argument: 1" ]

output stderr  command fail         =>

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
