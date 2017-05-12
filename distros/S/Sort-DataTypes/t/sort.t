#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Sort';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

BEGIN { $t->use_ok('Date::Manip'); }
Date_Init("TZ=EST");

sub test {
  ($method,$list,@args)=@_;
  sort_by_method($method,$list,@args);
  return @$list;
}

$tests = '
alphabetic [ foo bar zed ] =>
   bar
   foo
   zed

rev_date [ "Jul 4 2000" "May 31 2000" "Dec 31 1999" "Jan 3 2001" ] =>
  "Jan 3 2001"
  "Jul 4 2000"
  "May 31 2000"
  "Dec 31 1999"

domain [ aaa.bbb aa.bbb ] \.  =>
  aa.bbb
  aaa.bbb

rev_domain [ aaa::bbb::ccc bbb::ccc aaa::ccc ] :: =>
  aaa::bbb::ccc
  bbb::ccc
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

