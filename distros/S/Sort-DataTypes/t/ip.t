#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'IP';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,@args)=@_;
  sort_ip($list,@args);
  return @$list;
}

$tests = "
[ 128.227.208.63 10.227.208.42 128.227.208.75 10.227.208.3 ] =>
  10.227.208.3
  10.227.208.42
  128.227.208.63
  128.227.208.75

[ 10.20.30.40 10.20.30.41/4 10.20.30.41 10.20.30.42 10.20.30.41/16 ] =>
  10.20.30.40
  10.20.30.41
  10.20.30.41/4
  10.20.30.41/16
  10.20.30.42
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

