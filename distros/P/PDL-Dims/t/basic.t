#!perl 
use 5.012;
use strict;
use warnings FATAL => 'all';
use Test::Simple tests => 6;
#use PDL;
use PDL;
#use lib 'lib';
use PDL::Dims ; #qw/initdim/;
use PDL::NiceSlice;


# ( require PDL::Dims);
my $a=ones(2,3,4,5,6);
$a->hdr;
my $b=ones(2,4,6,2,5);
#a(x,y,z,t,e)
#b(x,z,e,f,t)
initdim($a,'x',size=>2);
initdim($a,'y',size=>3);
initdim($a,'z',size=>4);
initdim($a,'t',size=>5);
initdim($a,'e',size=>6);
#say dimsize ($a,'x');
my @l;
ok (@{dimname ($a)} eq ( @l=qw(x y z t e)),'initdim and dimname');
copy_dim($a,$b,'x');
ok(dimsize($b,'x')==2, 'copy_dim and dimsize');
ok (($a->dims == @{dimsize($a)}) ,'initdim and dimsize');
copy_dim($a,$b,'z');
copy_dim($a,$b,'e');
initdim($b,'f',pos=>3);
copy_dim($a,$b,'t');
#initdim($b,'a',size=>6);
ok (dimsize($b,'f')==2, 'another copy_dim test');
ok (didx($b,'t')==4,'didx');
ok(is_sane($b)==0,'sanity');
#diag( "Testing PDL::Dims $PDL::Dims::VERSION, Perl $], $^X" );
