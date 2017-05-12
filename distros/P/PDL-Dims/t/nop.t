#!perl 
use 5.012;
use strict;
use warnings FATAL => 'all';

use PDL;
use PDL::Dims ; #qw/initdim/;
use PDL::NiceSlice;
use Test::Simple tests => 11;

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
ok(!is_sane(ncop(sln($a,x=>0),$b,'mult',0)),'ncop_size=1');
ok((my @x=pos2i($b,'a','c')==42),'init');
ok(pos2i($b,'a','c'),'pos2i');
ok(sclr(sln($a,x=>0,y=>1))**2==4 ,'sln'); #$a(0,1;-)**2,'sln');
ok(sclr (nagg($a,'sumover','y')->(1))==9,'nagg');
#undef $a,$b;
ok(sclr(nop($a,'rotate','y',1)->(1,0))==5,'rotate');
ok(max (ncop($a,$b,'plus',0))==5,'ncop_method');
ok(max (ncop($a,$b,\&my_add))==5,'ncop_function');
ok((nreduce ($a,'add','y','x'))==15,'nreduce');
ok((nop($a,'cos',)->(1,2)==cos(5)),'nop_cos');
$a(0,1).=33;
sln($a,x=>0,y=>1).=33;
#(my $nix=sln($a,x=>0,y=>1)).=33;
ok(sclr(sln($a,x=>0,y=>1))==33 ,'sln-assign'); #$a(0,1;-)**2,'sln');
#diag( "Testing PDL::Dims $PDL::Dims::VERSION, Perl $], $^X" );
