#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Domain';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,@args)=@_;
  sort_domain($list,@args);
  return @$list;
}

$tests = '
[ aaa.bbb aa.bbb ] \.  =>
  aa.bbb
  aaa.bbb

[ aaa.bbb.ccc bbb.ccc aaa.ccc ] \.  =>
  aaa.ccc
  bbb.ccc
  aaa.bbb.ccc

[ aaa.bbb aaa.ccc ] =>
  aaa.bbb
  aaa.ccc

[ aaa::bbb aa::bbb ] :: =>
  aa::bbb
  aaa::bbb

[ aaa::bbb::ccc bbb::ccc aaa::ccc ] :: =>
  aaa::ccc
  bbb::ccc
  aaa::bbb::ccc

[ aaa::bbb aaa::ccc ] :: =>
  aaa::bbb
  aaa::ccc

';

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

