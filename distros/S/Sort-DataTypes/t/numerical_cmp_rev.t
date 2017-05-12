#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Numerical Reverse Compare';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($x,$y,@args)=@_;
  return cmp_rev_numerical($x,$y,@args);
}

$tests = "
1 3            => 1

2 2            => 0

3 1            => -1

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();


1;
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

