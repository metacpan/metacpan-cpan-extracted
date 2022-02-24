#!perl 
use 5.012;
use strict;
use warnings FATAL => 'all';

use PDL;
use PDL::Dims ; #qw/initdim/;
use PDL::NiceSlice;
use Test::Simple tests => 14;

sub my_add {
	return $_[0]+$_[1];
}
#sub ok{}
$a=sequence(6)->reshape(2,3);
initdim ($a,'x',size=>2);
initdim ($a,'y',);
$b=zeroes(3,4,2,3);
initdim( $b,'y',);
initdim( $b,'a',vals =>['a','b','c','d']);
initdim( $b,'u',);
initdim( $b,'b',);
drot($a,undef,undef,identity(2));
drot($b,undef,undef,identity(4));
ok(all(drot($a)==identity($a->ndims)),'trivial rot');
my $err=is_sane(my $f=sln($a,x=>0));
ok(!$err,'is_sane sln ?'.$err.drot($a)); #1
ok((my @x=pos2i($b,'a','c')==42),'init'); #2
ok(pos2i($b,'a','c'),'pos2i'); #3
ok(sclr(sln($a,x=>0,y=>1))**2==4 ,'sln'); #$a(0,1;-)**2,'sln'); #4
ok(sclr (nagg($a,'sumover','y')->(1))==9,'nagg'); #5
#undef $a,$b;
ok(sclr(nop($a,'rotate','y',1)->(1,0))==5,'rotate'); #6
ok(max (ncop($a,$b,'plus',0))==5,'ncop_method'); #7
ok(max (ncop($a,$b,\&my_add))==5,'ncop_function'); #8
ok((nreduce ($a,'add','y','x'))==15,'nreduce'); #9
ok((nop($a,'cos',)->(1,2)==cos(5)),'nop_cos'); #10
$a(0,1).=33;
sln($a,x=>0,y=>1).=33;
#(my $nix=sln($a,x=>0,y=>1)).=33;
ok(sclr(sln($a,x=>(0),y=>1))==33 ,'sln-assign'); #$a(0,1;-)**2,'sln'); #11
#diag( "Testing PDL::Dims $PDL::Dims::VERSION, Perl $], $^X" );
#warn (diminfo($b),diminfo($f));
$err=is_sane($f);
ok(!$err,"f ok? $err");
$err=is_sane($b);
ok(!$err,"b ok? $err");
$err=is_sane(ncop($f,$b,'mult',0));
#ok(!$err,'ncop '.$err); #12
#warn "NCOP passed.";
#ok(!is_sane($f*$b),'overload_ncop'); #13 overload not working, needs derived class!
