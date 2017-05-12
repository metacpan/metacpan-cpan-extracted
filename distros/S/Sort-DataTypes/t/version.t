#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Version';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,@args)=@_;
  sort_version($list,@args);
  return @$list;
}

$tests = "
[ 1.1.x 1.2 1.2.x ] => 1.1.x 1.2 1.2.x

[ 1.aaa 1.bbb ]     => 1.aaa 1.bbb

[ 1.2a 1.2 1.03 ]   => 1.2a 1.2 1.03

[ 1.a 1.2a ]        => 1.a 1.2a

[ 1.01a 1.1a ]      => 1.01a 1.1a

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

