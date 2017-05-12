#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Split';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,@args)=@_;
  sort_split($list,@args);
  return @$list;
}

$tests = "

[ 'a c d' 'a b c' 'a b' 'a a x' ]     => 'a a x' 'a b' 'a b c' 'a c d'

[ a:c:d a:b:c a:b a::x a:a:x ] :      => a::x a:a:x a:b a:b:c a:c:d

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

