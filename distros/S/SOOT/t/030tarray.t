use strict;
use warnings;
use Test::More tests => 291;
use SOOT;
use SOOT::API qw/:all/;
pass();

TODO: {
  local $TODO = 'Leaktest TArray*';
  fail();
}

foreach my $type (qw(TArrayD TArrayF TArrayI TArrayL TArrayS TArrayC)) {
  check_ary([1,2,3], $type);
  check_ary([1], $type);
  check_ary([1..20], $type);
}
foreach my $type (qw(TArrayD TArrayF)) {
  check_ary([1.,2,3], $type);
  check_ary([1.], $type);
  check_ary([map {$_*1.} (1..20)], $type);
}
pass("alive");

sub check_ary {
  my $perlary = shift;
  my $class = shift;
  my $ary = $class->new($perlary);
  isa_ok($ary, $class);
  my $clone = $ary->GetArray();
  is_deeply($clone, $perlary);
  my $index = 0;
  is($ary->GetSize(), scalar(@$perlary));
  foreach my $elem (@$perlary) {
    is($ary->GetAt($index++), $elem);
  }
  $ary->SetAt(2, 0);
  is($ary->GetAt(0), 2);
}
