package PDL::RungeKutta;
require Exporter;
use PDL;
use PDL::NiceSlice;

use constant RKA => pdl[0,          1/5, 3/10,        3/5,         1,         7/8];
use constant RKC => pdl[37/378,     0,   250/621,     125/594,     0,         512/1771];
use constant RKD => pdl[2825/27648, 0,   18575/48384, 13525/55296, 277/14336, 1/4];

use constant RKB => pdl[[0,          0,       0,           0,            0       ],
                        [1/5,        0,       0,           0,            0       ],
                        [3/40,       9/40,    0,           0,            0       ],
                        [3/10,       -9/10,   6/5,         0,            0       ],
                        [-11/54,     5/2,     -70/27,      35/27,        0       ],
                        [1631/55296, 175/512, 575/13824,   44275/110592, 253/4096]];

@ISA	   = qw(Exporter);
@EXPORT    = qw(rk5 rkevolve);

$VERSION='0.01';

#----------------- 5-order RK with Cash-Karp Parameters -----------------
sub rk5 {
  my ($t,$y,$h,$DE) = @_;
  my ($a,$b,$c,$d)  = (RKA,RKB,RKC,RKD);
  my $k = zeroes($y->dims,6);
  $k(,0) .= $h*&$DE($t,$y);
  my $w = $y + $c(0)*$k(,(0));
  my $delta = ($c(0)-$d(0))*$k(,0);
  for (my $j=1; $j<=5; $j++){
    $k(,$j) .= $h * &$DE($t+$a($j)*$h, $y+$b(:$j-1,$j) x $k(,:$j-1));
    $w += $c($j)*$k(,($j));
    $delta += ($c($j)-$d($j))*$k(,$j);
  }
  return ($w,$delta);
}
#-------------------------------------------------------------------------


#-------------- adaptive stepsize driver routine for rk ------------------
sub rkevolve {
  my ($t0,$y0,$h0,$DE,$T,$eps,$eseval,$esargs,$verbose) = @_;
  my $evy=($y0->dummy(0))->transpose;
  my $evd=zeroes($y0->dims,1); 
  my $evt=pdl($t0)->dummy(0);
  my $y=$y0; my $S=0.85; my $t=$t0; my $h=$h0;   my $i=0; my $j=0;
  my $del;   my $del0;   my $scale; my $inflate; my $shrink;
  $|=1 if $verbose eq 1;
  while ($t<=$T) {
    ($y,$del) = rk5($t,$y,$h,$DE);$t+=$h;
    $del0  = $eps*&$eseval($t,$y,@$esargs); # desired error
    $scale = min((abs($del0)+1.e-100)/(abs($del)+1.e-100)); # worst case
    if ($scale ge 1){               # error smaller than desired error
      $i++;
      $inflate=$S*$scale**(1/5);              # increase $h
      $inflate=5 if $inflate > 5;             #    and
      $h*=$inflate;                           # store result
      $evy=$evy->glue(1,$y->dummy(1));   
      $evd=$evd->glue(1,$del);
      $evt=$evt->glue(0,pdl($t)->dummy(0));
    } else {                        # error larger than desired error
      $j++;$t-=$h;
      $shrink=$S*$scale**(1/4);             # decrease $h
      $shrink=0.1 if $shrink < 0.1;         #   and   
      $h*=$shrink;                          # reset result
      $y.=$evy(,(-1));  
    }
    print "\t$T\t$t  \t$i  \t$j  \r" if $verbose eq 1;
  }
  print "\n" if $verbose eq 1;
  return ($evt,$evy,$evd,$i,$j);
}
#-------------------------------------------------------------------------

1;

__END__

=head1 NAME

PDL::RungeKutta - Solve N-th order M dimensional ordinary differential 
equations using adaptive stepsize Runge Kutta method.

=head1 DESCRIPTION

This module allows to solve N-th order M dimensional ordinary differential 
equations. It uses the  adaptive stepsize control for fifth order Cash-Karp
Runge-Kutta  algorithm described in  "Numerical Recipes in Fortran 77: The Art
of Scientific Computing" Ch. 16.2. The errors are estimated as the difference
between fifth order results and the embeded forth order results. To solve N-th
order equations, you must first turn it into a system of N
first order equations.

=head1 SYNOPSIS

Example: Solve  y'' + y = 0, y(0) = 0, y'(0) = 1

  use PDL;								       
  use PDL::Math;							       
  use PDL::NiceSlice;							       
  use PDL::RungeKutta;							       

  # y'' + y = 0, Solution: y = sin(t)					       

  $Y0 = pdl(0,1);	    # y(0)=0, y'(0)=1	( Y0=(f,g), f=y, g=y' )	       
  @esargs=();		    # extra arguments for error eval function    
  $t0  = 0;		    # initial moment				       
  $dt0 = 0.1;		    # initial time step 			       
  $t1  = 1 0;		    # final moment				       
  $eps = 1.e-6; 	    # error					       
  $verbose=1;								       

  # integration 							       
  ($evt,$evy,$evd,$i,$j) = 						       
  rkevolve($t0,$Y,$dt0,\&DE,$t1,$eps,\&error,\@esargs,$verbose);	       

  $check=sin($evt);							       
  wcols $evt,$evy((0)),$check,'test.dat';				       

  sub DE {		  # differential eq				       
    my ($t,$y)= @_;							       
    my $yd=zeroes(2);		    # Y'    ( = (f',g') = (y',y'') )	       
    $yd(0).=$y(1);		    # f'=g  ( = y' )			       
    $yd(1).=-$y(0);		    # g'=-f ( =-y )			       
    return $yd; 							       
  }									       

  sub error {		    # error scale 				       
    my ($t,$Y) = @_;							       
    my $es=ones(2);	    # constant scale				       
    return $es; 							       
  }
  		
Please see the other examples also.
									       
=head1 Exported Functions

=head2 rkevolve

($t,$Y,$d,$i,$j) = rkevolve($t0,$Y0,$dt0,$DE,$t1,$eps,$erfcn,$efarg,$verbose)

This will solve the differential equation for B<DE> with the initial conditions 
B<Y0> between B<t0> and B<t1> using adaptive step size control for Runge-Kutta.

=item B<Input>

=item * $t0 scalar, initial moment

=item * $Y0 one dimensional piddle wich contains the initial conditions. Number
of elements is  NxM.

=item * $dt0 scalar, initial time step

=item * $DE reference to the function for the differential equation.
Please see Math::ODE(3) for a more detailed description on how to construct the 
equations. It should return a piddle with the same dimensions as $Y0.

=item * $t1 scalar, final moment

=item * $eps scalar, the requested error. Upon scaling with the output of erfcn 
this will give the requested error for each element of $Y.

=item * $erfcn reference to the error scaling function. This function should 
return a pidle containing scaling factors for the requested error for each
element of $Y. Please see Num. Rec. for more details.

=item * $efarg reference to an array containing supplementary arguments for
erfcn.

=item * $verbose scalar, integer. If set to 1 details about progress are printed
during calculation.

=item B<Output>

=item * $t piddle containing the independent variable

=item * $Y piddle containing the results

=item * $d piddle containing the errors as estimated by Cash-Karp Runge-Kutta
algorithm

=item * $i total number of iterations

=item * $j number of resets made in order to decrease the error

=head2 rk5

($y,$del) = rk5($t,$yi,$h,$DE)

This will carry out one Cash-Karp Runge-Kutta step. Could be useful if you want
to do your own step size control or you just want equal steps.

=item B<Input>

=item * $t initial moment

=item * $yi piddle containing the initial conditions

=item * $h step

=item * $DE reference to differential equation

=item B<Output>

=item * $y piddle containing the result

=item * $del piddle containing the errors

=head1 AUTHOR

Dragos Constantinescu <dragos@venus.nipne.ro>

=head1 SEE ALSO

Math::ODE(3)

"Numerical Recipes in Fortran 77: The Art of Scientific Computing" Ch. 16.

http://lib-www.lanl.gov/numerical/index.html

=head1 COPYRIGHT

Copyright (c) 2003 by Dragos Constantinescu.  All rights reserved.

=head1 LICENSE AGREEMENT

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
