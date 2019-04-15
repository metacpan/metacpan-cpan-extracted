use strict;
use Test::More;
use Config;

sub inpath {
  my ($prog) = @_;
  for ( split $Config{path_sep}, $ENV{PATH} ) {
    return 1 if -x "$_/$prog$Config{exe_ext}"
  }
  return;
}

BEGIN {
   eval "use Convert::UU;";
   my $hasuuencode = !$@ || (inpath('uuencode') && inpath('uudecode'));

   if ($hasuuencode) {
      plan tests => 17;
   } else {
      plan skip_all => "Skip neither uuencode/decode nor Convert:UU is available\n";
   }

   use PDLA;
}

########### First test the load...
use_ok('PDLA::IO::Dumper');

########### Dump several items and make sure we get 'em back...
# a: trivial
# b: 0-d
# c: inline
# d: advanced expr

my ( $s, $a );

eval '$s = sdump({a=>3,b=>pdl(4),c=>xvals(3,3),d=>xvals(4,4)});';
is $@, '', 'Call sdump()'
   or diag("Call sdump() output string:\n$s\n");
$a = eval $s;
is $@, '', 'Can eval dumped data code' or diag("The output string was '$s'\n");
ok(ref $a eq 'HASH', 'HASH was restored');
ok(($a->{a}==3), 'SCALAR value restored ok');
ok(((ref $a->{b} eq 'PDLA') && ($a->{b}==4)), '0-d PDLA restored ok');
ok(((ref $a->{c} eq 'PDLA') && ($a->{c}->nelem == 9) 
      && (sum(abs(($a->{c} - xvals(3,3))))<0.0000001)), '3x3 PDLA restored ok');
ok(((ref $a->{d} eq 'PDLA') && ($a->{d}->nelem == 16)
      && (sum(abs(($a->{d} - xvals(4,4))))<0.0000001)), '4x4 PDLA restored ok');

########## Dump a uuencoded expr and try to get it back...
# e: uuencoded expr
eval '$s = sdump({e=>xvals(25,25)});';
is $@, '', 'sdump() of 25x25 PDLA to test uuencode dumps';

#diag $s,"\n";

$a = eval $s;
is $@, '', 'Can eval dumped 25x25 PDLA' or diag 'string: ', $s;

ok((ref $a eq 'HASH'), 'HASH structure for uuencoded 25x25 PDLA restored');
ok(((ref $a->{e} eq 'PDLA') 
      && ($a->{e}->nelem==625)
      && (sum(abs(($a->{e} - xvals(25,25))))<0.0000001)), 'Verify 25x25 PDLA restored data');

########## Check header dumping...
eval '$a = xvals(2,2); $a->sethdr({ok=>1}); $a->hdrcpy(1); $b = xvals(25,25); $b->sethdr({ok=>2}); $b->hdrcpy(0); $s = sdump([$a,$b,yvals(25,25)]);';
is $@, '', 'Check header dumping';

$a = eval $s;
is $@, '', 'ARRAY can restore';
is ref($a), 'ARRAY' or diag explain $a;

ok(eval('$a->[0]->hdrcpy() == 1 && $a->[1]->hdrcpy() == 0'), 'Check hdrcpy()\'s persist');
ok(eval('($a->[0]->gethdr()->{ok}==1) && ($a->[1]->gethdr()->{ok}==2)'), 'Check gethdr() values persist');

# end
