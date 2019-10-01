#!/usr/bin/perl -wT
use strict;
use lib qw(.);
use CayleyDickson;

# generate some CayleyDickson number objects ...
my $one     = CayleyDickson->new(1,0,0,0);
my $i       = CayleyDickson->new(0,1,0,0);
my $j       = CayleyDickson->new(0,0,1,0);
my $k       = CayleyDickson->new(0,0,0,1);
my $o1      = CayleyDickson->new(1,2,3,4,-3,-2,-1);
my $o2      = CayleyDickson->new(3,0,2,-1,0-2,1,-1);
my $c       = CayleyDickson->new(sqrt(1/4),sqrt(3/4));
my $d       = CayleyDickson->new(sqrt(1/2),-sqrt(1/2));
my $e       = CayleyDickson->new(sqrt(3/5),sqrt(2/5));
my $f       = CayleyDickson->new(sqrt(1/5),sqrt(4/5));
my $ii      = $i*$i;
my $ij      = $i*$j;
my $ji      = $j*$i;
my $jj      = $j*$j;
my $ipj     = $i+$j;
my $nipj    = $ipj->norm;
my $kk      = $k*$k;
my $ijk     = $i * $j * $k;
my $inv_i   = $i->inverse;
my $o1po2   = $o1+$o2;
my $o1so2   = $o1-$o2;
my $o1mo2   = $o1*$o2;
my $o1do2   = $o1/$o2;
my $o1o1    = $o1*$o1;
my $invo2o2 = 1/($o2*$o2);
my $t       = $d->tensor($c);
my $o       = $t->tensor($e);
my $s       = $o->tensor($f);
my $ss      = $s*$s;
my $invs    = 1/$s;
my $invss   = 1/$ss;
my $tconj   = $t->conjugate;
my $invt    = 1/$t;
my $tmd     = $t*$d;
my $tdd     = $t/$d;
my $ntmd    = $tmd->norm;

# display them ...
print <<END;
#################################################
#
# "Hyper Complex Numbers using CayleyDickson.pm"
#     copyright 2019 - Jeffrey B Anderson
#        "truejeffanerson at gmail.com"
# 
#################################################

Given these Quaternions ...

    "1"= [1,0,0,0] = $one
     i = [0,1,0,0] = $j
     j = [0,0,1,0] = $k
     k = [0,0,0,1] = $k

Then ...

     i × i = $ij
     j × j = $jj
     k × k = $kk
 i × j × k = $ijk
       i⁻¹ = $inv_i
     j × i = $ji
     i + j = $ipj
     amplitude/norm of i + j = |i+j| = $nipj

Given these Octonions ...

    o1 = $o1
    o2 = $o2

Then ...
    
    o1 × o2 = $o1mo2
    o1 / o2 = $o1do2
    o1 + o2 = $o1po2
    o1 - o2 = $o1mo2
        o1² = $o1o1
        o2⁻²= $invo2o2

Tensor Example ...

   c = $c
   d = $d

After tensoring t = c ⊗  d ...

     t = $t

     this is a Quaternion

And also ...

    t* = $tconj (conjugate of c)
   t⁻¹ = $invt (inversion of c)
   t×d = $tmd
   t/d = $tdd
   norm(t/d) = $ntmd

   
Now we create an Oction by tensoring again...

   let e = $e
   o = e ⊗  t
   o = $o

Now we create an Sedonion by tensoring again...

   let f = $f
   s = f ⊗  o
   s = $s

And math on this already works since it is recursive...

   s² = $ss
   s⁻²= $invss
   s/t = $s/$t

END

## object dumping tool ...
#sub d {
#my %a = @_;
#my @k = keys %a;
#my $d = Data::Dumper->new([@a{@k}],[@k]); $d->Purity(1)->Deepcopy(1); print $d->Dump;
#}

1;

__END__

