#!/usr/bin/perl
use PDL;
use PDL::Fit::Levmar;
use PDL::NiceSlice;

# This example shows how to fit a bivariate Gaussian. Here
# is the fit function.

sub gauss2d {
    my ($p,$xin,$t) = @_;
    my ($p0,$p1,$p2) = list $p;
    my $n = $t->nelem;
    my $t1 = $t(:,*$n); # first coordinate
    my $t2 = $t(*$n,:); # second coordinate
    my $x = $xin->splitdim(0,$n);
    $x .= $p0 * exp( -$p1*$t1*$t1 - $p2*$t2*$t2);
}

# We would prefer a function that maps t(n,n) --> x(n,n) (with
# p viewed as parameters.) But the levmar library expects one
# dimensional x and t. So we design C<gauss2d> to take
# piddles with these dimensions: C<p(3)>, C<xin(n*n)>,
# C<t(n)>. For this example, we assume that both the co-ordinate
# axes run over the same range, so we only need to pass n
# values for t. The piddles t1 and t2 are (virtual) copies of
# t with dummy dimensions inserted. Each represents
# co-ordinate values along each of the two axes at each point
# in the 2-d space, but independent of the position along the
# other axis.  For instance C<t1(i,j) == t(i)> and C<t1(i,j)
# == t(j)>. We assume that the piddle xin is a flattened
# version of the ordinate data, so we split the dimensions in
# x. Then the entire bi-variate gaussian is calculated with
# one line that operates on 2-d matrices. Now we create some
# data,
    
   my $n = 101;  # number of data points along each axis
   my $scale = 3; # range of co-ordiate data
   my $t = sequence($n); # co-ordinate data (used for both axes)
   $t *= $scale/($n-1);
   $t  -= $scale/2;     # rescale and shift.
   my $x = zeroes($n,$n);
   my $p = pdl  [ .5,2,3]; # actual parameters
   my $xlin = $x->clump(-1); # flatten the x data
   gauss2d( $p, $xlin, $t->copy); # compute the bivariate gaussian data.


# Now x contains the ordinate data (so does xlin, but in a flattened shape.)
# Finally, we fit the data with an incorrect set of initial parameters,

   my $p1 = pdl  [ 1,1,1];  # not the parameters we used to make the data
   my $h = levmar($p1,$xlin,$t,\&gauss2d);

# At this point C<$h->{P}> refers to the output parameter piddle C<[0.5, 2, 3]>.

print $h->{P} , "\n";
