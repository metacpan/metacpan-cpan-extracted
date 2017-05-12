#!/usr/bin/perl -w

BEGIN {
  use Test::Inter;
  $t = new Test::Inter 'Function (by name)';
}

BEGIN { $t->use_ok('Sort::DataTypes',':all'); }

sub test {
  ($list,$func)=@_;
  sort_function($list,$func);
  return @$list;
}

# Do an alphabetic sort in the order e a c b d
sub testcmp1 {
   my($x,$y) = @_;

   my %val = qw( a 3  b 2  c 1  d 5  e 4 );

   my $xval  = $val{ substr($x,0,1) };
   my $yval  = $val{ substr($y,0,1) };

   if ($xval < $yval) {
      return -1;
   } elsif ($xval > $yval) {
      return 1;
   } else {
      return $x cmp $y;
   }
}

$tests = "
[ abc acb bcd bdc cab deb eel ] testcmp1 =>
  cab
  bcd
  bdc
  abc
  acb
  eel
  deb

[ abc acb bcd bdc cab deb eel ] sortfuncs::testcmp2 =>
  eel
  abc
  acb
  cab
  bcd
  bdc
  deb

";

$t->tests(func  => \&test,
          tests => $tests);
$t->done_testing();

package sortfuncs;

# Do an alphabetic sort in the order e a c b d
sub testcmp2 {
   my($x,$y) = @_;

   my %val = qw( a 2  b 4  c 3  d 5  e 1 );

   my $xval  = $val{ substr($x,0,1) };
   my $yval  = $val{ substr($y,0,1) };

   if ($xval < $yval) {
      return -1;
   } elsif ($xval > $yval) {
      return 1;
   } else {
      return $x cmp $y;
   }
}

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

