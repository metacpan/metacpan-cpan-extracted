#!/usr/bin/perl

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Valid Ele';
}

BEGIN { $t->use_ok('Set::Files'); }
my $testdir = $t->testdir();

sub valid_ele {
  my($set,$ele) = @_;
  return 1  if ($ele eq "a"  ||  $ele eq "d");
  return 0;
}

sub test {
   my($valid) = @_;
   my $q = new Set::Files("path"          => "$testdir/dir4",
                          "invalid_quiet" => 1,
                          "valid_ele"     => $valid
                         );
   $q->members('a1');
}

$t->tests(func     => \&test,
          tests    => ['^(a|b)', '!(a|b)', \&valid_ele],
          expected => "a b

                       c d

                       a d
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

