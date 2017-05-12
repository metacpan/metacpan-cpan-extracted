#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL
#
#  ROC.pm - A Perl module implementing receiver-operator-characteristic (ROC)
#           curves with nonparametric confidence bounds
#
#     Copyright (c) 1998 Hans A. Kestler. All rights reserved.
#     This program is free software; you may redistribute it and/or
#     modify it under the same terms as Perl itself.
#
#  This code implements a method for constructing nonparametric confidence
#  for ROC curves described in     
#        R.A. Hilgers, Distribution-Free Confidence Bounds for ROC Curves, 
#        Meth Inform Med 1991; 30:96-101
#  Additionally some auxilliary functions were ported (and corrected) from 
#  Fortran (Applied Statistics, ACM).
#
#  Written in Perl by Hans A. Kestler.
#  Bugs, comments, suggestions to: 
#              Hans A. Kestler <hans.kestler@uni-ulm.de>
#                              <h.kestler@ieee.org>
#
#
#LLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLLL

package Statistics::ROC;
require 5;
use Carp;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = ('Exporter');
@EXPORT = qw(
     roc rank loggamma betain Betain xinbta Xinbta	
);
$VERSION = '0.01';




# Algorithm 291, Logarithm of the gamma function. 
#                in Collected Algorithms of the ACM, Vol II, 1980
# M.C. Pike and I.D. Hill with remark by M.R. Hoare
# see also Pike, M.C. and Hill, I.D. (1966). Algorithm 291. Logarithm of the
#          gamma function. Commun. Ass. Comput. Mach., 9,684.

sub loggamma($){
    # This procedure evaluates the natural logarithm of gamma(x) for all
    # x>0, accurate to 10 decimal places. Stirlings formula is used for the
    # central polynomial part of the procedure
    
    my $x= shift; # default arg is @_
    my ($f, $z);
    
    
    if($x==0){return 743.746924740801} # this is: loggamma(9.9999999999E-324)
    
    if($x < 7)
    {
       for($z=$x,$f=1;$z<7;$z++)
       {
       $x=$z; $f*=$z;
       }
       $x++;
       $f= -log($f); # log returns the natural logarithm
    }
    else{ $f=0;}
    $z=1/($x*$x);
    return $f+($x-.5)*log($x)-$x+.918938533204673+
       (((-.000595238095238*$z+.000793650793651)*$z-
           .002777777777778)*$z+.083333333333333)/$x;
}



# Algorithm AS 63 with remark AS R19, 
# Computes incomplete beta function ratio 
#  K.L. Majumder and G.P. Bhattacharjee (1973). The Incomplete Beta Integral,
#  Appl. Statist.,22:409:411  and
#  G.W. Cran, K.J. Martin and G.E. Thomas (1977).Remark AS R19 and 
#  Algorithm AS109, A Remark on Algorithms AS 63: The Incomplete Beta Integral
#  AS 64: Inverse of the Incomplete Beta Function Ratio, 
#  Appl. Statist., 26:111-114.
#
# Remarks:
#    Complete beta function: B(p,q)=gamma(p)*gamma(q)/gamma(p+q)
#                       log(B(p,q))=ln(gamma(p))+ln(gamma(q))-ln(gamma(p+q))
#
#    Incomplete beta function ratio:
#                 I_x(p,q)=1/B(p,q) * \int_0^x t^{p-1}*(1-t)^{q-1} dt
#
#    --> log(B(p,q)) has to be supplied to calculate I_x(p,q)
#    log denotes the natural logarithm
#        $beta = log(B(p,q))
#        $x    = x
#        $p    = p
#        $q    = q
#    The subroutine returns I_x(p,q). If an error occurs a negative value 
#    {-1,-2} is returned.
 
sub betain($$$$){
    # Computes incomplete beta function ratio for arguments
    # $x between zero and one, $p and $q positive.
    # Log of complete beta function, $beta, is assumed to be known.
    
    my ($x, $p, $q, $beta) = @_;
    my ($xx, $psq, $cx, $pp, $qq, $index, $betain, 
        $ns, $term, $ai, $rx, $temp);
    my $ACU=1.0E-14;  # accuracy
    
    # tests for admissibility of arguments
    if($p<=0 || $q<=0){ return -1;} 
    if($x<0  || $x>1) { return -2;}

    # change tail if necessary and determine s
    $psq=$p+$q; $cx=1-$x;
    if($p<$psq*$x){ $xx=$cx; $cx=$x; $pp=$q; $qq=$p; $index=1;}
    else{ $xx=$x; $pp=$p; $qq=$q; $index=0;}
    $term=1; $ai=1; $betain=1; 
    $ns=$qq+$cx*$psq;
    
    # use Soper's reduction formulae
    $rx=$xx/$cx;
    do{
        if($ns>=0){$temp=$qq-$ai; if($ns==0){$rx=$xx;}}
        else{ $temp=$psq; $psq++;}
        $term *= $temp*$rx/($pp+$ai);
        $betain+=$term;
        $temp=abs($term); $ai++; $ns--;}
    until($temp<=$ACU && $temp<=$ACU*$betain);
    
    # calculate result
    $betain *= exp($pp*log($xx)+($qq-1)*log($cx)-$beta)/$pp;
    if($index){ return 1-$betain;}
    else{ return $betain;}
}    
    
sub Betain($$$){
    # Computes the incomplete beta function 
    # by calling loggamma() and betain()
    my ($x, $p, $q) = @_;
    
    if($x==1){return 1;}
    elsif($x==0){return 0;}
    else{ return betain($x, $p, $q,loggamma($p)+loggamma($q)-loggamma($p+$q));}
}

sub max($$){
    # computes the maximum of two numbers
    my ($a, $b) = @_;
    
    if($a>$b){ return $a;}
    else{ return $b;}
}


# Algorithm AS 109,
# Computes inverse of incomplete beta function ratio
#  G.W. Cran, K.J. Martin and G.E. Thomas (1977).Remark AS R19 and 
#  Algorithm AS109, A Remark on Algorithms AS 63: The Incomplete Beta Integral
#  AS 64: Inverse of the Incomplete Beta Function Ratio, 
#  Appl. Statist., 26:111-114.
#
#  Remark AS R83 and the correction in vol40(1) of Appl. Statist.(1991), p.236 
#  have been incorporated in this version.
#  K.J. Berry, P.W. Mielke, Jr and G.W. Cran (1990) Algorithm AS R83, A Remark
#  on Algorithm AS 109: Inverse of the Incomplete Beta Function Ratio,
#  Appl. Statist., 39:309-310. 
#
# Remarks:
# 
#    Complete beta function: B(p,q)=gamma(p)*gamma(q)/gamma(p+q)
#                       log(B(p,q))=ln(gamma(p))+ln(gamma(q))-ln(gamma(p+q))
#
#    Incomplete beta function ratio:
#              alpha = I_x(p,q) = 1/B(p,q) * \int_0^x t^{p-1}*(1-t)^{q-1} dt
#
#    --> log(B(p,q)) has to be supplied to calculate I_x(p,q)
#    log denotes the natural logarithm
#        $beta = log(B(p,q))
#        $alpha= I_x(p,q)
#        $p    = p
#        $q    = q
#    The subroutine returns x. If an error occurs a negative value {-1,-2,-3}
#    is returned.
      
sub xinbta($$$$){
    # Computes inverse of incomplete beta function ratio
    # for given positive values of the arguments $p and $q,
    # $alpha between zero and one.
    # Log of complete beta function, $beta is assumed to be known.   
    #
    # copyright by H.A. Kestler, 1998

    my ($p, $q, $beta, $alpha) = @_;
    my ($a, $y, $pp, $qq, $index, $r, $h, $t, $w, $xinbta,
        $yprev, $prev,$s, $sq, $tx, $adj, $g);
    my $SAE=-37;
    my $FPU=10**$SAE;
    my $ACU;
    
    # test for admissibility of parameters
    if($p<=0 || $q<=0){ return -1;} 
    if($alpha<0   || $alpha>1) { return -2;}
    if($alpha==0  || $alpha==1){ return $alpha;}
    
    # change tail if necessary
    if($alpha>.5){ $a=1-$alpha; $pp=$q; $qq=$p; $index=1;}
    else{ $a=$alpha; $pp=$p; $qq=$q; $index=0;}
    
    # calculate the initial approximation
    $r=sqrt(-log($a*$a));
    $y=$r-(2.30753+.27061*$r)/(1+(.99229+.04481*$r)*$r);
    if($pp>1 && $qq > 1)
    {
      $r=($y*$y-3)/6; $s=1/($pp+$pp-1); $t=1/($qq+$qq-1);
      $h=2/($s+$t); 
      $w=$y*sqrt($h+$r)/$h-($t-$s)*($r+5/6-2/(3*$h));
      $xinbta=$pp/($pp+$qq*exp($w+$w));
    }
    else
    {
      $r=$qq+$qq; $t=1/(9*$qq);
      $t=$r*(1-$t+$y*sqrt($t))**3;
      if($t<=0){ 
        $xinbta=1-exp((log((1-$a)*$qq)+$beta)/$qq);
      }
      else{ 
        $t=(4*$pp+$r-2)/$t;
        if($t<=1){ $xinbta=exp((log($a*$pp)+$beta)/$pp);}
        else{ $xinbta=1-2/($t+1);}
      }
    }
        
    # solve for $x by a modified newton-raphson method
    # using subroutine betain()
    $r=1-$pp; $t=1-$qq; $yprev=0; $sq=1; $prev=1;
    if($xinbta<.0001){ $xinbta=.0001;}
    if($xinbta>.9999){ $xinbta=.9999;}
    $ACU=10**(max(-5/$pp**2-1/$a**.2-13,$SAE));
    do{
        $y=betain($xinbta,$pp,$qq,$beta);
        if($y==-1 || $y==-2){ return -3;}  # betain returns an exception
        $y=($y-$a)*exp($beta+$r*log($xinbta)+$t*log(1-$xinbta));
        if($y*$y<=0){ $prev=max($sq,$FPU);}
        $g=1;
        Label10: do{
                     do{ $adj=$g*$y; $sq=$adj*$adj; $g/=3;} while($sq>=$prev);
                     $tx=$xinbta-$adj;}
                 until($tx>=0 && $tx<=1);
        if($prev<=$ACU || $y*$y<=$ACU){ goto Label12;}
        if($tx==0 || $tx==1){ goto Label10;}
        $xinbta=$tx; $yprev=$y;}
     until($adj==0);
     
     Label12:
     if($index){ return 1-$xinbta;}
     else{ return $xinbta;}
}


sub Xinbta($$$){
    # Computes the inverse of the incomplete beta function 
    # by calling loggamma() and xinbta()
    #
    # copyright by H.A. Kestler, 1998

    my ($p, $q, $alpha) = @_;
    
    if($alpha==1){return 1;}
    elsif($alpha==0){return 0;}
    else{ return xinbta($p, $q,loggamma($p)+loggamma($q)-loggamma($p+$q),
                        $alpha);}
}



sub rank($\@){
    # Computes the ranks of the values specified as the second 
    # argument (an array). Returns a vector of ranks 
    # corresponding to the input vector.
    # Different types of ranking are possible ('high', 'low', 'mean'),
    # and are specified as first argument.
    # These differ in the way ties of the input vector, i.e. identical
    # values, are treated: 
    #    'high' --> replace ranks of identical values with their
    #               highest rank
    #    'low'  --> replace ranks of identical values with their
    #               lowest rank
    #    'mean' --> replace ranks of identical values with the mean
    #               of their rank
    #
    # copyright by H.A. Kestler, 1998
    
    my ($type, $r) = @_; # $type: type of ranking 'high', 'low' or 'mean' 
                         # $r: reference to array of values to be ranked   
    my (@s, $s, $i, @e, @rk, $rk_m);
    
    # calculate initial rank's 
    @s=sort{$$r[$a]<=>$$r[$b]} 0..$#{$r}; # sort idx num. by values of @r 
    for($i=0,@rk=@s;$i<@rk;$i++){ $rk[$s[$i]]=$i+1;} # set rank's 
    
    # treat ties
    for($i=1,@e=(); $i<@s; $i++){
       if($$r[$s[$i]]==$$r[$s[$i-1]]){ # test if there are ties
          push @e,$i-1;}   # save index numbers of tied values (minus 1)
       elsif(@e){ # ties have occured and are now being treated
          if($type eq'mean'){  # calculate mean value of tied ranks
             $rk_m=0; 
             for(@e,$e[-1]+1){ $rk_m+=$rk[$s[$_]];} $rk_m/=@e+1;
          }
          for(@e,$e[-1]+1){
              if($type    eq 'high'){ $rk[$s[$_]]=$rk[$s[$e[-1]+1]];}
              elsif($type eq 'low' ){ $rk[$s[$_]]=$rk[$s[$e[0]]];}
              elsif($type eq 'mean'){ $rk[$s[$_]]=$rk_m;}
              else{ croak "Wrong type of ranking (high|low|mean).\n";}
          }
          @e=(); # reinitialize @e
       }
    }
    return @rk;
}


sub locate(\@$){ 
    # Routine to find the index for table lookup which is below
    # the value to be interpolated.
    # Given a reference to an array $xx and a value $x a value $j
    # is returned such that $x is between $xx[$j] and $xx[$j+1].
    # $xx must be monotonic, either increasing or decreasing.
    #
    # This routine is adapted from "Numerical Recipes in C",
    # second edition, by Press, Teukolsky, Vetterling and Flannery,
    # Cambridge University Press, 1992.
    # It uses bisection to find the right place, which has a
    # comutational complexity of O(log_2(n)).
    #
    # copyright by H.A. Kestler, 1998

    my ($xx,$x)=@_;
    my ($jl,$ju)=(0,$#{$xx}); # initialize lower and upper limits
    my ($jm,$ascend);
    
    $ascend=$$xx[$ju] > $$xx[0];
    
    # test if $x is inside of the array
    if(($x>$$xx[$ju] || $x<$$xx[$jl]) && $ascend)
       { croak "Value out of range for table lookup (1): $x.\n";}
    if(($x<$$xx[$ju] || $x>$$xx[$jl]) && !$ascend)
       { croak "Value out of range for table lookup (2): $x.\n";}
    
    while(($ju-$jl)>1) {                  # If we are not yet done
          $jm=int(($ju+$jl)/2);           # compute a midpoint,
          if($x > $xx->[$jm] == $ascend) 
            { $jl=$jm;}                   # and replace either the lower limit
          else 
            { $ju=$jm;}                   # or the upper limit, as appropriate.
    }
    return $jl;
}


sub linlocate(\@$$){ 
    # Routine to find the index for table lookup which is below
    # the value to be interpolated.
    # Given a reference to an array $xx and a value $x a value $j
    # is returned such that $x is between $xx[$j] and $xx[$j+1].
    # $xx must be monotonic, either increasing or decreasing.
    #
    # Starts searching linearly from an initial index value
    # provided as the third argument.
    # If no index value can be found a negative value is 
    # returned, i.e. -1.
    #
    # copyright by H.A. Kestler, 1998
 
    my ($xx,$x,$index)=@_; 
    my ($jl,$ju)=(0,$#{$xx}); # initialize lower and upper limits
    my $ascend;
    
    $ascend=$$xx[$ju] > $$xx[0];
    
    # test if $x is inside of the array
    if(($x>$$xx[$ju] || $x<$$xx[$jl]) && $ascend)
       { croak "Value out of range for table lookup.\n";}
    if(($x<$$xx[$ju] || $x>$$xx[$jl]) && !$ascend)
       { croak "Value out of range for table lookup.\n";}
    
    # step through the table sequentially    
    if($ascend && $xx->[$index]<$x){     # ascending
       while($x>$xx->[$index] and $index<=$ju) { $index++;}}
    elsif(!$ascend && $xx->[$index]>$x){ # descending
       while($x<$xx->[$index] and $index<=$ju) { $index++;}}
    else{ return -1;}    # starting index is too high
    
    return $index-1;
}


sub interp(\@\@\@){
    # Interpolates (table lookup) piecewise linearly an 
    # array (third argument). Returns
    # The table is represented by the first two arguments, i.e. @xx and @yy.
    # Assumes the @xx values to be monotonically increasing.
    #
    # copyright by H.A. Kestler, 1998
 
    use vars ('@xx', '@yy', '@x');
    local (*xx, *yy, *x)=@_;    
    my ($i, $index, @y);
    
    # make checks
    if(@xx != @yy) {croak "Sizes of xx and yy arrays are not equal.\n";}
    
    for($i=0; $i<@x; $i++)
    {
        $index=locate(@xx,$x[$i]); 
        $y[$i]=($yy[$index+1]-$yy[$index])/($xx[$index+1]-$xx[$index])*
               ($x[$i]-$xx[$index]) + $yy[$index];
    }    
    return @y;    
}    


sub roc($$\@){
    # ROC (receiver operator characteristic) curves with confidence bounds
    # 
    # Determines the ROC curve and its nonparametric confidence bounds.
    # The ROC curve shows the relationship of "probability of false
    # alarm" (x-axis) to "probability of detection" (y-axis) for a 
    # certain test.
    # Or in medical terms: the "probability of a positive test, given no 
    # disease" to the "probability of a positive test, given disease".
    # The ROC curve may be used to determine an "optimal" cutoff
    # point for the test.
    #
    # The routine takes three arguments:
    #  (1) type of model: 'decrease' or 'increase', this states the assumption
    #      that a higher ('increase') value of the data tends to be an 
    #      indicator of a positive test result or for the model 'decrease'
    #      a lower value.
    #  (2) two-sided confidence interval (usually 0.95 is chosen).
    #  (3) the data stored as a list-of-lists:
    #      each entry in this list consits of an "value / true group" pair, 
    #      i.e. value / disease present. Group values are from {0,1}.
    #      0 stands for disease (or signal) not present (prior knowledge) and
    #      1 for disease (or signal) present (prior knowledge).
    #      Example: @s=([2, 0], [12.5, 1], [3, 0], [10, 1], [9.5, 0], [9, 1]);
    #      Notice the small overlap of the groups. The
    #      optimal cutoff point to separate the two groups would be between
    #      9 and 9.5 if the criterion of optimality is to maximize the
    #      probability of detection and simultaneously minimize the 
    #      probability of false alarm.
    #
    # Returns a list-of-lists with the three curves:
    #      @ROC=([@lower_b], [@roc], [@upper_b]) each of the curves is
    #      again a list-of-lists with each entry consisting of one (x,y) pair.
    # The routine impelements the method described in: 
    # R.A. Hilgers, Distribution-Free Confidence Bounds for ROC Curves, 
    # Meth Inform Med 1991; 30:96-101
    #
    # copyright by H.A. Kestler, 1998
    
    my $model_type = shift;   # assign 
    my $conf       = shift;
    use vars '@val_grp';
    local (*val_grp)=@_;
    
    my ($cu, $cl, $elem, $n1, $n0, $i, $j);
    my @grp1=();my @grp0=();
    my (@f_l_1,@f_m_1,@f_h_1,@f_l_0,@f_m_0,@f_h_0,@mat,@xx,@yy,@x,@y,@index);
    my (@lower_b ,@roc ,@upper_b, @ROC);
    
    # make checks
    if($conf>=1 || $conf<=0){ croak 
       "The nominal 2-sided confidence limit must be a number of [0,1].\n";}
    if($model_type ne 'increase' && $model_type ne 'decrease'){ croak
       "Wrong model type specified!\n";}   
    
    $cu=(sqrt($conf)+1)/2;   # calculate the one-sided upper
    $cl=1-$cu;               # and lower confidence limits 
    
    # extract values
    for($i=0;$i<@val_grp;$i++){
        if($val_grp[$i][1]==1) { push @grp1, $val_grp[$i][0];}
        else                   { push @grp0, $val_grp[$i][0];}
    }
    
    # compute ranks and values of inverse incomplete beta function
    @f_l_1=rank('low' ,@grp1);
    @f_m_1=rank('mean',@grp1);
    @f_h_1=rank('high',@grp1);
    @f_l_0=rank('low' ,@grp0);
    @f_m_0=rank('mean',@grp0);
    @f_h_0=rank('high',@grp0);
    
    
    $n1=@grp1; $n0=@grp0;    # number of elements in both arrays
    for $elem (@f_l_1){ $elem=Xinbta($elem,$n1+1-$elem,$cl);}
    for $elem (@f_m_1){ $elem=Xinbta($elem,$n1+1-$elem,0.5);}
    for $elem (@f_h_1){ $elem=Xinbta($elem,$n1+1-$elem,$cu);}
    for $elem (@f_l_0){ $elem=Xinbta($elem,$n0+1-$elem,$cl);}
    for $elem (@f_m_0){ $elem=Xinbta($elem,$n0+1-$elem,0.5);}
    for $elem (@f_h_0){ $elem=Xinbta($elem,$n0+1-$elem,$cu);}

            
    # merge and sort 
    @mat=();
    for($i=0;$i<$n1;$i++){ push @mat, [($grp1[$i], -1, -1, -1, 
                                       $f_l_1[$i], $f_m_1[$i], $f_h_1[$i])];} 
    for($i=0;$i<$n0;$i++){ push @mat, [($grp0[$i],$f_l_0[$i], $f_m_0[$i], 
                                       $f_h_0[$i], -1, -1, -1)];}     
    # sort numerically according to value in first column   
    @mat=@mat[sort{$mat[$a][0] <=> $mat[$b][0]} 0..$#mat];
    

    # for practical purposes augment @mat and fill missing data (-1)
    # at the beginning and end of the matrix
    unshift @mat,[-1, 0, 0, Xinbta(1,$n0,$cu), 0, 0, Xinbta(1,$n1,$cu)];
    push    @mat,[-1, Xinbta($n0,1,$cl), 1, 1, Xinbta($n1,1,$cl), 1, 1];
    for($i=1;$mat[$i][1]==-1; $i++){
        $mat[$i][1]=0; $mat[$i][2]=0; $mat[$i][3]=$mat[0][3];}
    for($i=1;$mat[$i][4]==-1; $i++){
        $mat[$i][4]=0; $mat[$i][5]=0; $mat[$i][6]=$mat[0][6];}
    for($i=$#mat-1;$mat[$i][1]==-1; $i--){
        $mat[$i][1]=$mat[$#mat][1]; $mat[$i][2]=1; $mat[$i][3]=1;}
    for($i=$#mat-1;$mat[$i][4]==-1; $i--){
        $mat[$i][4]=$mat[$#mat][4]; $mat[$i][5]=1; $mat[$i][6]=1;}

    
    # replace missing data (-1) with a piecewise linear interpolation
    for($j=1;$j<7;$j++) # iterate thru columns
    {
       for($i=1,@xx=(),@yy=(),@x=(),@index=();$i<$#mat;$i++){ 
          push @xx, $mat[$i][0]  if $mat[$i][$j] !=-1;
          push @yy, $mat[$i][$j] if $mat[$i][$j] !=-1;
          push @x,  $mat[$i][0]  if $mat[$i][$j] ==-1;
          push @index, $i        if $mat[$i][$j] ==-1;
       }
       @y=interp(@xx,@yy,@x); 
       for($i=0;$i<@index;$i++){ $mat[$index[$i]][$j]=$y[$i];}
    }
    
    
    # calculate (x,y) pairs of ROC curve and its limit curves 
    # (lower, ROC, upper) according to specified model
    for($i=0,@lower_b=(),@roc=(),@upper_b=(),;$i<@mat;$i++){
       if($model_type eq 'decrease'){
          push @lower_b, [($mat[$i][3], $mat[$i][4])];
          push @roc,     [($mat[$i][2], $mat[$i][5])];
          push @upper_b, [($mat[$i][1], $mat[$i][6])];
       }
       else{
          push @lower_b, [(1-$mat[$i][3], 1-$mat[$i][4])];
          push @roc,     [(1-$mat[$i][2], 1-$mat[$i][5])];
          push @upper_b, [(1-$mat[$i][1], 1-$mat[$i][6])];
       }
    }
    
    @ROC=([@lower_b], [@roc], [@upper_b]);
    return  @ROC;              
}    




# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__


=head1 NAME

Statistics::ROC - receiver-operator-characteristic (ROC) curves with nonparametric confidence bounds



=head1 SYNOPSIS

  use Statistics::ROC;

  my ($y)    = loggamma($x);
  my ($y)    = betain($x, $p, $q, $beta);
  my ($y)    = Betain($x, $p, $q);
  my ($y)    = xinbta($p, $q, $beta, $alpha);
  my ($y)    = Xinbta($p, $q, $alpha);
  my (@rk)   = rank($type, \@r);
  my (@ROC)  = roc($model_type,$conf,\@val_grp);
  

=head1 DESCRIPTION

This program determines the ROC curve and its nonparametric confidence bounds for
data categorized into two groups.
A ROC curve shows the relationship of B<probability of false alarm> (x-axis) to 
B<probability of detection> (y-axis) for a certain test.
Expressed in medical terms: the B<probability of a positive test, given no disease>
to the B<probability of a positive test, given disease>.
The ROC curve may be used to determine an I<optimal> cutoff point for the test.

The main function is B<roc()>. The other exported functions are used by B<roc()>, but
might be useful for other nonparametric statistical procedures.


=over 4

=item B<loggamma>

This procedure evaluates the natural logarithm of gamma(x) for all
x>0, accurate to 10 decimal places. Stirlings formula is used for the
central polynomial part of the procedure. 
For C<x=0> a value of  743.746924740801 will be returned: this is 
loggamma(9.9999999999E-324).


=item B<betain>

Computes incomplete beta function ratio 

    Remarks:
    Complete beta function: B(p,q)=gamma(p)*gamma(q)/gamma(p+q)
                       log(B(p,q))=ln(gamma(p))+ln(gamma(q))-ln(gamma(p+q))

    Incomplete beta function ratio:
                 I_x(p,q)=1/B(p,q) * \int_0^x t^{p-1}*(1-t)^{q-1} dt

    --> log(B(p,q)) has to be supplied to calculate I_x(p,q)
    log denotes the natural logarithm
        $beta = log(B(p,q))
        $x    = x
        $p    = p
        $q    = q
    The subroutine returns I_x(p,q). If an error occurs a negative value 
    {-1,-2} is returned.



=item B<Betain> 

Computes the incomplete beta function by calling B<loggamma()> and B<betain()>.



=item B<xinbta> 

Computes inverse of incomplete beta function ratio

    Remarks:
 
    Complete beta function: B(p,q)=gamma(p)*gamma(q)/gamma(p+q)
                       log(B(p,q))=ln(gamma(p))+ln(gamma(q))-ln(gamma(p+q))

    Incomplete beta function ratio:
              alpha = I_x(p,q) = 1/B(p,q) * \int_0^x t^{p-1}*(1-t)^{q-1} dt

    --> log(B(p,q)) has to be supplied to calculate I_x(p,q)
    log denotes the natural logarithm
        $beta = log(B(p,q))
        $alpha= I_x(p,q)
        $p    = p
        $q    = q
    The subroutine returns x. If an error occurs a negative value {-1,-2,-3}
    is returned.
      


=item B<Xinbta>

Computes the inverse of the incomplete beta function by calling B<loggamma()> 
and B<xinbta()>.


=item B<rank>

Computes the ranks of the values specified as the second argument (an array). 
Returns a vector of ranks corresponding to the input vector.
Different types of ranking are possible ('high', 'low', 'mean'), and are 
specified as first argument. These differ in the way ties of the input vector, 
i.e. identical values, are treated: 

=over 10

=item * B<high>: 

replace ranks of identical values with their highest rank
       

=item * B<low>:   

replace ranks of identical values with their lowest rank
       

=item * B<mean>:

replace ranks of identical values with the mean of their ranks


=back
   

=item B<roc>

Determines the ROC curve and its nonparametric confidence bounds.
The ROC curve shows the relationship of "probability of false
alarm" (x-axis) to "probability of detection" (y-axis) for a 
certain test.
Or in medical terms: the "probability of a positive test, given no 
disease" to the "probability of a positive test, given disease".
The ROC curve may be used to determine an "optimal" cutoff
point for the test.

The routine takes three arguments:

(1) type of model: 'decrease' or 'increase', this states the assumption
that a higher ('increase') value of the data tends to be an 
indicator of a positive test result or for the model 'decrease'
a lower value.

(2) two-sided confidence interval (usually 0.95 is chosen).

(3) the data stored as a list-of-lists:
each entry in this list consits of an "value / true group" pair, 
i.e. value / disease present. Group values are from {0,1}.
0 stands for disease (or signal) not present (prior knowledge) and
1 for disease (or signal) present (prior knowledge).
Example: @s=([2, 0], [12.5, 1], [3, 0], [10, 1], [9.5, 0], [9, 1]);
Notice the small overlap of the groups. The
optimal cutoff point to separate the two groups would be between
9 and 9.5 if the criterion of optimality is to maximize the
probability of detection and simultaneously minimize the 
probability of false alarm.

Returns a list-of-lists with the three curves:
      @ROC=([@lower_b], [@roc], [@upper_b]) each of the curves is
      again a list-of-lists with each entry consisting of one (x,y) pair.


=back

=over 4

=head2 Examples

   $,=" ";
   print loggamma(10), "\n";
   print Xinbta(3,4,Betain(.6,3,4)),"\n";
   
   @e=(0.7, 0.7, 0.9, 0.6, 1.0, 1.1, 1,.7,.6);
   print rank('low',@e),"\n";
   print rank('high',@e),"\n";
   print rank('mean',@e),"\n";

   @var_grp=([1.5,0],[1.4,0],[1.4,0],[1.3,0],[1.2,0],[1,0],[0.8,0],
          [1.1,1],[1,1],[1,1],[0.9,1],[0.7,1],[0.7,1],[0.6,1]);
   @curves=roc('decrease',0.95,@var_grp);
   print "$curves[0][2][0]  $curves[0][2][1] \n";


=head1 AUTHOR

Hans A. Kestler,  I<hans.kestler@uni-ulm.de>     B<or> 
I<h.kestler@ieee.org>


=head1 SEE ALSO
     

Perl/Tk userinterface for drawing ROC curves (requires installed Tk and X11 on MacOS X).


R.A. Hilgers, Distribution-Free Confidence Bounds for ROC Curves (1991), 
I<Meth Inform Med>, 30:96-101


Algorithm 291, Logarithm of the gamma function. 
I<Collected Algorithms of the ACM>, Vol II, 1980
     

I<Numerical Recipes in C>, second edition, by Press, Teukolsky, Vetterling and Flannery,
Cambridge University Press, 1992.


G.W. Cran, K.J. Martin and G.E. Thomas (1977).Remark AS R19 and 
Algorithm AS109, A Remark on Algorithms AS 63: The Incomplete Beta Integral
AS 64: Inverse of the Incomplete Beta Function Ratio, 
I<Appl Statist>, 26:111-114.


K.J. Berry, P.W. Mielke, Jr and G.W. Cran (1990) Algorithm AS R83, A Remark
on Algorithm AS 109: Inverse of the Incomplete Beta Function Ratio,
I<Appl Statist>, 39:309-310. 


=cut
