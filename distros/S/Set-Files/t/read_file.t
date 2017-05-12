#!/usr/bin/perl

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Read File';
}

BEGIN { $t->use_ok('Set::Files'); }
my $testdir = $t->testdir();

sub test1 {
   my $q = new Set::Files("path" => "$testdir/dir5");
   $q->list_sets();
}

$t->is(\&test1,[],['a','b','c']);

sub test2 {
   my($set) = @_;

   my $q = new Set::Files("path" => "$testdir/dir5",
                          "read" => "file",
                          "set"  => $set,
                         );
   $q->list_sets();
}

$t->tests(func     => \&test2,
          tests    => "a  => a

                       b  => a b

                       c  => a b c
                      ");
$t->done_testing();

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: -2
# End:

