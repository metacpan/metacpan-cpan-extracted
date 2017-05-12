#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Partial';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,@args)=@_;
  sort_partial($list,@args);
  return @$list;
}

$tests = "

[ '3 Smith John'
  '20 Smith Evan'
  '100 Smith Jim'
  '20 Tyson Lynn'
  '3 Able Seth'
  '20 Smith Abram'
  '100 Smith Jack'
  '3 Smith Amy'
  '100 Dyson Nick' ]
[ 1 [ numerical ] ]
[ 2 ]
[ 3 ]
   =>
   '3 Able Seth'
   '3 Smith Amy'
   '3 Smith John'
   '20 Smith Abram'
   '20 Smith Evan'
   '20 Tyson Lynn'
   '100 Dyson Nick' 
   '100 Smith Jack'
   '100 Smith Jim'

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

