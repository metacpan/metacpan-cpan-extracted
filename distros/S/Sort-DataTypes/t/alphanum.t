#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Alphanum';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,@args)=@_;
  sort_alphanum($list,@args);
  return @$list;
}

$tests = "

[ a ab 1 4 2 cb ca ] => 1 2 4 a ab ca cb

[ c a 1.1 0.9 -1.1 ] => -1.1 0.9 1.1 a c

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

