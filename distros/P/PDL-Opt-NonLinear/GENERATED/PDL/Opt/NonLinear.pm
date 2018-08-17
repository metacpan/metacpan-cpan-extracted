
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::Opt::NonLinear;

@EXPORT_OK  = qw( PDL::PP tensoropt PDL::PP lbfgs PDL::PP lbfgsb PDL::PP spg PDL::PP lmqn PDL::PP lmqnbc PDL::PP cgfam PDL::PP hooke PDL::PP gencan PDL::PP sgencan PDL::PP dhc PDL::PP de_opt PDL::PP asa_opt  rosen rosen_grad rosen_hess optimize );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::Opt::NonLinear::VERSION = 0.05;
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::Opt::NonLinear $VERSION;




use strict;
use PDL::Ufunc;
use PDL::Ops;
use PDL::NiceSlice;
use PDL::LinearAlgebra qw/diag tritosym/;


=head1 NAME

PDL::Opt::NonLinear -- Non Linear optimization routines

=head1 SYNOPSIS

 use PDL::Opt::NonLinear;

 $x = random(5);
 $gx = rosen_grad($x);
 $fx = rosen($x);

 $xtol = pdl(1e-16);
 $gtol = pdl(0.9);
 $eps = pdl(1e-10);
 $print = ones(2);
 $maxit = pdl(long, 200);
 $info = pdl(long,0);
 sub fg_func{
	my ($f, $g, $x) = @_;
	$f .= rosen($x);
	$g .= rosen_grad($x);		
 }
 cgfam($fx, $gx, $x, $maxit, $eps, $xtol, $gtol,$print,$info,1,\&fg_func);

=head1 DESCRIPTION

This module provides routine that solves optimization problem:

   	minimize     f(x)
	   x

Some routines can handle bounds, so:

   	minimize     f(x)
	   x
   	subject to   low <= x <= up

=cut








=head1 FUNCTIONS



=cut






=head2 tensoropt

=for sig

  Signature: ([io,phys]fx();[io,phys]gx(n);[io,phys]hx(n,n);[io,phys]x(n);int [phys]method();int [io,phys]maxit();int [phys]digits();int [phys]gtype();int [phys] htype();[phys]fscale();[phys]typx(n);[phys]stepmx();[phys]xtol();[phys]gtol();int [phys]print();int [io,phys]ipr(); SV* f_func;SV* g_func;SV* h_func)



=for ref

This routine solves the optimization problem

           minimize f(x)
              x

where x is a vector of n real variables.
The derivative tensor method method bases each iteration
on a specially constructed fourth order model of the objective function.
The model interpolates the function value and gradient from the previous
iterate and the current function value, gradient and hessian
matrix.


parameters:

	fx      --> function value and final function value
	gx(n)   <-- current gradient and gradient at final point
	hx(n,n) --> hessian
	x(n)    --> initial guess (input) and final point
	method  --> if value is 0 then use only newton step at
 		    each iteration, if value is 1 then try both
		    tensor and newton steps at each iteration
	maxit   <-- iteration limit and final number of iterations
	digits  --> number of good digits in optimization function fcn
	gtype   --> = 0: gradient computed by finite difference
		      1: analytical gradient supplied is checked
		      2: analytical gradient supplied
	htype   --> = 0: hessian computed by finite difference
		      1: analytical hessian supplied is checked
		      2: analytical hessian supplied
	fscale  --> estimate of scale of objective function fcn
	typx(n) --> typical size of each component of x
	stepmx  --> maximum step length allowed
	xtol    --> step tolerance
	gtol    --> gradient tolerance
	ipr     --> output unit number
	print   --> output message control
	f_func:
		parameter: PDL(fx), PDL(x)
	g_func:
		parameter PDL(gx), PDL(x)
	h_func:
		parameter PDL(hx), PDL(x)

=for example

	$x = random(5);
	$gx = rosen_grad($x);
	$hx = rosen_hess($x);
	$fx = rosen($x);

	$xtol = pdl(1e-16);
	$gtol = pdl(1e-8);

	$stepmx =pdl(0.5);
	$maxit = pdl(long, 50);

	sub min_func{
		my ($fx, $x) = @_;
		$fx .= rosen($x);
	}
	sub grad_func{
		my ($gx, $x) = @_;
		$gx .= rosen_grad($x);
	}
	sub hess_func{
		my ($hx, $x) = @_;
		$hx .= rosen_hess($x);
	}
	tensoropt($fx, $gx, $hx, $x, 
		1,$maxit,15,1,2,1,
		ones(5),0.5,$xtol,$gtol,2,6,
		\&min_func, \&grad_func, \&hess_func);




=for bad

tensoropt ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*tensoropt = \&PDL::tensoropt;





=head2 lbfgs

=for sig

  Signature: ([io,phys]fx(); [io,phys]gx(n); [io,phys]x(n);[io,phys]diag(n);int [phys]diagco();int [phys]m();int [io,phys]maxit();int [io,phys]maxfc();[phys]eps();[phys]xtol();[phys]gtol();int [phys]print(2);int [io,phys]info(); SV* fg_func;SV* diag_func)



=for ref

This subroutine solves the unconstrained minimization problem
 
		min f(x),    x= (x1,x2,...,xn),

using the limited memory bfgs method. The routine is especially
effective on problems involving a large number of variables. In
a typical iteration of this method an approximation hk to the
inverse of the hessian is obtained by applying m bfgs updates to
a diagonal matrix hk0, using information from the previous m steps.
The user specifies the number m, which determines the amount of
storage required by the routine. The user may also provide the
diagonal matrices hk0 if not satisfied with the default choice.
The algorithm is described in "on the limited memory bfgs method
for large scale optimization", by d. liu and j. nocedal,
mathematical programming b 45 (1989) 503-528.

The steplength is determined at each iteration by means of the
line search routine mcvsrch, which is a slight modification of
the routine csrch written by Moré and Thuente.
 
 
      where
 
     m       The number of corrections used in the bfgs update. it
             is not altered by the routine. values of m less than 3 are
             not recommended; large values of m will result in excessive
             computing time. 3<= m <=7 is recommended. restriction: m > 0.
 
     x       On initial entry, it must be set by the user to the values
             of the initial estimate of the solution vector. 
	     On exit with info=0, it contains the values of the variables 
	     at the best point found (usually a solution).
 
     f       is a double precision variable. before initial entry and on
             a re-entry with info=1, it must be set by the user to
             contain the value of the function f at the point x.
 
     g       is a double precision array of length n. before initial
             entry and on a re-entry with info=1, it must be set by
             the user to contain the components of the gradient g at
             the point x.
 
     diagco  is a logical variable that must be set to 1 if the
             user  wishes to provide the diagonal matrix hk0 at each
             iteration. Otherwise it should be set to 0, in which
             case  lbfgs will use a default value described below.
 
     diag    is a double precision array of length n. if diagco=.true.,
             then on initial entry or on re-entry with info=2, diag
             it must be set by the user to contain the values of the 
             diagonal matrix hk0.  Restriction: all elements of diag
             must be positive.

     print   is an integer array of length two which must be set by the
             user.
 
             print(1) specifies the frequency of the output:
                print(1) < 0 : no output is generated,
                print(1) = 0 : output only at first and last iteration,
                print(1) > 0 : output every print(1) iterations.
 
             print(2) specifies the type of output generated:
                print(2) = 0 : iteration count, number of function 
                                evaluations, function value, norm of the
                                gradient, and steplength,
                print(2) = 1 : same as print(2)=0, plus vector of
                                variables and  gradient vector at the
                                initial point,
                print(2) = 2 : same as print(2)=1, plus vector of
                                variables,
                print(2) = 3 : same as print(2)=2, plus gradient vector.
 
     maxit   On entry maximum number of iteration.
	     On exit, the number of iteration.

     maxfc   On entry maximum number of function evaluation.
	     On exit, the number of function evaluation.
 
     eps     is a positive double precision variable that must be set by
             the user, and determines the accuracy with which the solution
             is to be found. the subroutine terminates when

                         ||g|| < eps max(1,||x||),

             where ||.|| denotes the euclidean norm.
 
     xtol    is a  positive double precision variable that must be set by
             the user to an estimate of the machine precision (e.g.
             10**(-16) on a sun station 3/60). The line search routine will
             terminate if the relative width of the interval of uncertainty
             is less than xtol.

     gtol    is a double precision variable which controls the accuracy of 
     	     the line search routine mcsrch. If the function and gradient 
             evaluations are inexpensive with respect to the cost of the 
	     iteration (which is sometimes the case when solving very large 
	     problems) it may be advantageous to set gtol to a small value. 
	     A typical small value is 0.1. It's set to 0.9 if gtol < 1.d-04.  
	     restriction: gtol should be greater than 1.d-04.
 
     info    is an integer variable that must be set to 0 on initial entry
             to the subroutine. A return with info < 0 or info > 2 indicates 
	     an error.  
             The following values of info, detecting an error,
             are possible:
 
              info=-1  the i-th diagonal element of the diagonal inverse
                        hessian approximation, given in diag, is not
                        positive.
           
              info=-2  improper input parameters for lbfgs (n or m are
                        not positive).

              info=-3  error in user subroutine.

             if  info > 2 the line search routine mcsrch failed:

                       info = 3  more than 20 function evaluations were
                                 required at the present iteration.

                       info = 4  the step is too small.

                       info = 5  the step is too large.

                       info = 6  rounding errors prevent further progress. 
                                 there may not be a step which satisfies
                                 the sufficient decrease and curvature
                                 conditions. tolerances may be too small.

                       info = 7  relative width of the interval of
                                 uncertainty is at most xtol.

                       info = 8  improper input parameters.
 
	fg_func:
		stop = fg_func PDL(fx), PDL(gx), PDL(x)

=for example

	$x = random(5);
	$gx = rosen_grad($x);
	$fx = rosen($x);
	$diag = zeroes(5);
	
	$xtol = pdl(1e-16);
	$gtol = pdl(0.9);
	$eps = pdl(1e-10);
	$print = ones(2);
	$maxfc = pdl(long,100);
	$maxit = pdl(long,50);
	$info = pdl(long,0);
	$diagco= pdl(long,0);
	$m = pdl(long,10);

	sub fdiag{};
	sub fg_func{
		my ($f, $g, $x) = @_;
		$f .= rosen($x);
		$g .= rosen_grad($x);
		return 0;
	}
	lbfgs($fx, $gx, $x, $diag, $diagco, $m, $maxit, $maxfc, $eps, $xtol, $gtol,
		$print,$info,\&fg_func,\&fdiag);



=for bad

lbfgs ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*lbfgs = \&PDL::lbfgs;





=head2 lbfgsb

=for sig

  Signature: ([io,phys]fx(); [io,phys]gx(n); [io,phys]x(n);int [phys]m();[phys]bound(n,m=2);int [phys]tbound(n);int [io]maxit();[phys]factr();[phys]pgtol();[phys]gtol();int [phys]print(2);int [io,phys]info();int [o,phys]iv(p=44);[o,phys]v(q=29); SV* fg_func)



=for ref

This routine solves the optimization problem

   minimize     f(x)
      x
   subject to   low <= x <= up

It uses the limited memory BFGS method.
(The direct method will be used in the subspace minimization.)

     x 
	is a double precision array of dimension n.
	On entry x is an approximation to the solution.
	On exit x is the current approximation.

     m
	On entry m is the maximum number of variable metric corrections
        used to define the limited memory matrix.
        On exit m is unchanged.

     bound(n,2)
	On entry bound(,0) is the lower bound on x.
	On entry bound(,1) is the upper bound on x.
	On exit bound(n,2) is unchanged.

     tbound(n)
	On entry nbd represents the type of bounds imposed on the
	variables, and must be specified as follows:
 	nbd(i)=0 if x(i) is unbounded,
                1 if x(i) has only a lower bound,
                2 if x(i) has both lower and upper bounds, and
                3 if x(i) has only an upper bound.
 	On exit nbd is unchanged.

     fx
	On first entry f is unspecified.
	On final exit f is the value of the function at x.

     gx(n)
	On first entry g is unspecified.
	On final exit g is the value of the gradient at x.

     maxit
     	On entry maximum number of iteration.
     	On exit, the number of iteration

     factr
	On entry factr >= 0 is specified by the user.  The iteration
        will stop when

	(f^k - f^{k+1})/max{|f^k|,|f^{k+1}|,1} <= factr*epsmch

	where epsmch is the machine precision, which is automatically
	generated by the code. Typical values for factr: 1.d+12 for
	low accuracy; 1.d+7 for moderate accuracy; 1.d+1 for extremely
	high accuracy.

     pgtol
	On entry pgtol >= 0 is specified by the user.  The iteration
	will stop when

	max{|proj g_i | i = 1, ..., n} <= pgtol

	where pg_i is the ith component of the projected gradient.   

     gtol
	Controls the accuracy of the line search routine mcsrch.
	If the function and gradient evaluations are inexpensive with 
	respect to the cost of the iteration (which is sometimes the case 
	when solving very large problems) it may be advantageous to set 
	gtol to a small value. A typical small value is 0.1. 
	It's set to 0.9 if gtol < 1.d-04. 
	Restriction: gtol should be greater than 1.d-04.

     print
	Controls the frequency and type of output generated:
         print[0] < 0      no output is generated;
         print[0] = 0      print only one line at the last iteration;
         0 < print[0] < 99 print also f and |proj g| every iprint iterations;
         print[0] = 99     print details of every iteration except n-vectors;
         print[0] = 100    print also the changes of active set and final x;
         print[0] > 100    print details of every iteration including x and g;
         When print[1] > 0, the file iterate.dat will be created to
                        summarize the iteration.
     info
     	On entry 0,
     	On exit, contain error code:
	  0 : no error
	  -1: the routine has terminated abnormally
              without being able to satisfy the termination conditions,
              x contains the best approximation found,
              f and g contain f(x) and g(x) respectively
          -2: the routine has detected an error in the
              input parameters;
     iv(44)
	On exit, at end of an iteration, the following information is
	available:
         iv(21) = the total number of intervals explored in the 
                         search of Cauchy points;
         iv(25) = the total number of skipped BFGS updates before 
                         the current iteration;
         iv(29) = the number of current iteration;
         iv(30) = the total number of BFGS updates prior the current
                         iteration;
         iv(32) = the number of intervals explored in the search of
                         Cauchy point in the current iteration;
         iv(33) = the total number of function and gradient 
                         evaluations;
         iv(35) = the number of function value or gradient
                                  evaluations in the current iteration;
         if iv(36) = 0  then the subspace argmin is within the box;
         if iv(36) = 1  then the subspace argmin is beyond the box;
         iv(37) = the number of free variables in the current
                         iteration;
         iv(38) = the number of active constraints in the current
                         iteration;
         n + 1 - iv(39) = the number of variables leaving the set of
                           active constraints in the current iteration;
         iv(40) = the number of variables entering the set of active
                         constraints in the current iteration.
	else

         iv(29) = the current iteration number;
         iv(33) = the total number of function and gradient
                         evaluations;
         iv(35) = the number of function value or gradient
                                  evaluations in the current iteration;
         iv(37) = the number of free variables in the current
                         iteration;
         iv(38) = the number of active constraints at the current
                         iteration

     v(29)
	On exit, at end of an iteration, the following information is
	available:
         v(0) = current 'theta' in the BFGS matrix;
         v(1) = f(x) in the previous iteration;
         v(2) = factr*epsmch;
         v(3) = 2-norm of the line search direction vector;
         v(4) = the machine precision epsmch generated by the code;
         v(6) = the accumulated time spent on searching for Cauchy points;
         v(7) = the accumulated time spent on subspace minimization;
         v(8) = the accumulated time spent on line search;
         v(10) = the slope of the line search function at 
		 the current point of line search;
         v(11) = the maximum relative step length imposed in line search;
         v(12) = the infinity norm of the projected gradient;
         v(13) = the relative step length in the line search;
         v(14) = the slope of the line search function at the starting point of the line search;
         v(15) = the square of the 2-norm of the line search direction vector.

     scalar fg_func: computes the value(fx) and gradient(gx) of the function at x.
		iv and v are also provided for info
		param fx, gx, x, iv, v
		return value
		 -1 stop now and restore the information at
		    the latest iterate
		 0  continue
		 1  last iteration



=for example

	# Global Optimization
	# Try to solve (with threading)
	# The SIAM 100-Digit Challenge problem 4 
	# see http://www-m8.ma.tum.de/m3/bornemann/challengebook/
	# result: -3.30686864747523728007611377089851565716648236
	use PDL::Opt::NonLinear;
	use PDL::Stat::Distributions;

	$x = (random(2,500)-0.5)*2;
	$gx = zeroes(2,500);
	$fx = zeroes(500);
        
	$bounds =  zeroes(2,2);
	$bounds(,0).= -1;
	$bounds(,1).= 1;

	$tbounds = zeroes(2);
	$tbounds .= 2;  

	$gtol = pdl(0.9);
	$pgtol = pdl(1e-4);

	$factr = pdl(10000);
	$m = pdl(10);

	$print = pdl([-1,0]);

	$maxit = zeroes(long,500);
	$maxit .= 200;

	$info = zeroes(long,500);

	$iv = zeroes(long,44,500);
	$v = zeroes(29,500);
	sub fg_func{
		my ($f, $g, $x) = @_;
	
		$f.= exp(sin(50*$x(0)))+sin(60*exp($x(1)))+ 
			sin(70*sin($x(0)))+sin(sin(80*$x(1)))-
                	sin(10*($x(0)+$x(1)))+($x(0)**2+$x(1)**2)/4;

		$g(0) .= 50*cos(50*$x(0))* exp(sin(50*$x(0)))+
        	        70*cos(70*sin($x(0)))*cos($x(0))-
                	10*cos(10*$x(0)+10*$x(1))+1/2*$x(0);
            
		$g(1) .= 60*cos(60*exp($x(1)))* exp($x(1))+ 
        	        80*cos(sin(80*$x(1)))* cos(80*$x(1))-
                	10*cos(10*$x(0)+10*$x(1))+1/2*$x(1);

		return 0;
	}
	lbfgsb($fx, $gx, $x, $m, $bounds, $tbounds, $maxit, $factr, $pgtol, $gtol,
                $print, $info,$iv, $v,\&fg_func);
	print $fx->min;


	# Local Optimization
	$x = random(5);
	$gx = zeroes(5);
	$fx = pdl(0);
	
	$bounds =  zeroes(5,2);
	$bounds(,0).= -5;
	$bounds(,1).= 5;
	$tbounds = zeroes(5);
	$tbounds .= 2;	
	$gtol = pdl(0.9);
	$pgtol = pdl(1e-10);
	$factr = pdl(100);
	$print = pdl(long, [1,0]);
	$maxit = pdl(long,100);
	$info = pdl(long,0);
	$m = pdl(long,10);
	$iv = zeroes(long,44);
	$v = zeroes(29);

	sub fg_func{
		my ($f, $g, $x) = @_;
		$f .= rosen($x);
		$g .= rosen_grad($x);
		return 0;
	}
	lbfgsb($fx, $gx, $x, $m, $bounds, $tbounds, $maxit, $factr, $pgtol, $gtol,
		$print, $info,$iv, $v,\&fg_func);



=for bad

lbfgsb ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*lbfgsb = \&PDL::lbfgsb;





=head2 spg

=for sig

  Signature: ([io,phys]fx();[io,phys]x(n);int [io,phys]m();int [io,phys]maxit();int [phys]maxfc();[phys]eps1();[phys]eps2();int [phys]print();int [io,phys]fcnt();int [io,phys]gcnt();[io,phys]pginf();[io,phys]pgtwon();int [io,phys]info(); SV* min_func; SV* grad_func; SV* px_func)



=for ref

This routine solves the optimization problem

           minimize f(x)
              x

where x is a vector of n real variables. The method used
is a  Spectral Projected Gradient
(Version 2: "continuous projected gradient direction") 
to find the local minimizers of a given function with convex
constraints, described in E. G. Birgin, J. M. Martinez, and M. Raydan,
"Nonmonotone spectral projected gradient methods on convex sets", SIAM 
Journal on Optimization 10, pp. 1196-1211, 2000. and  
E. G. Birgin, J. M. Martinez, and M. Raydan, "SPG: software 
for convex-constrained optimization", ACM Transactions on 
Mathematical Software, 2001 (to appear).

The user must supply the external subroutines evalf, evalg 
and proj to evaluate the objective function and its gradient 
and to project an arbitrary point onto the feasible region.

This version 17 JAN 2000 by E.G.Birgin, J.M.Martinez and M.Raydan.
Reformatted 03 OCT 2000 by Tim Hopkins.
Final revision 03 JUL 2001 by E.G.Birgin, J.M.Martinez and M.Raydan.

     On Entry:

     x(n)  initial guess,

     m     number of previous function values to be considered 
           in the nonmonotone line search,

     eps1  stopping criterion: ||projected grad||_inf < eps,

     eps2  stopping criterion: ||projected grad||_2 < eps2,

     maxit integer,
           maximum number of iterations,

     maxfc integer,
           maximum number of function evaluations,

     print logical,
           true: print some information at each iteration,
           false: no print.

     On Return:

     x(n)  approximation to the local minimizer,

     fx:   function value at the approximation to the local
           minimizer,

     pginfn
           ||projected grad||_inf at the final iteration,

     pgtwon
           ||projected grad||_2^2 at the final iteration,

     maxit
	   number of iterations,

     fcnt  number of function evaluations,

     gcnt  number of gradient evaluations,

     info  termination parameter:
           0= convergence with projected gradient infinite-norm,
           1= convergence with projected gradient 2-norm,
           2= too many iterations,
           3= too many function evaluations,
           4= error in proj subroutine,
           5= error in evalf subroutine,
           6= error in evalg subroutine.

     min_func:
	   parameter: PDL(fx), PDL(x)

     grad_func:
	   parameter: PDL(gx), PDL(x)

     px_func:
	   parameter: PDL(x)

=for example

	# Bounded example
	$bounds = zeroes(5,2);
	$bounds(,0) .= -5;
	$bounds(,1) .= 5;	
	$info = pdl(long,0);
	$print = pdl(long,1);
	$fcnt = pdl(long,0);
	$gcnt = pdl(long,0);
	$pginf = pdl(0);
	$pgtwon = pdl(0);
	$maxit = pdl(long , 500);
	$maxfc = pdl(long , 1000);
	$m = pdl(long , 100);
	$eps1 = pdl(0);
	$eps2 = pdl(1e-5);
	$fx = pdl(0);
	$a= random(5)
	sub pgrad{
		$x = shift;
		$c = minimum transpose(cat $x, $bounds(,1));
		$c = maximum transpose(cat $c, $bounds(,0));
		$x .=$c;
		return 0;
	}
	sub grad{
		($aa, $bb) = @_;
		$aa .= rosen_grad($bb);
		return 0;
	}
	sub min_func{
		($aa, $bb) = @_;
		$aa .= rosen($bb);
		return 0;
	}
	spg($fx, $a, $m, $maxit, $maxfc, $eps1, $eps2, $print, $fcnt, $gcnt, $pginf, $pgtwon, $info, \&min_func,\&grad, \&pgrad);



=for bad

spg ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*spg = \&PDL::spg;





=head2 lmqn

=for sig

  Signature: ([io,phys]fx();[io,phys]gx(n);[io,phys]x(n);int [io,phys]maxit();int [io,phys]maxfc();int [phys]cgmaxit();[phys]xtol();[phys]accrcy();[phys]eta();[phys]stepmx();int [phys]print();int [io,phys]info(); SV* fg_func)



=for ref

This routine solves the optimization problem

           minimize f(x)
              x

where x is a vector of n real variables. The method used is
a truncated-newton algorithm (see "newton-type minimization via
the lanczos method" by s.g. nash (siam j. numer. anal. 21 (1984),
pp. 770-778).  This algorithm finds a local minimum of f(x).  It does
not assume that the function f is convex (and so cannot guarantee a
global solution), but does assume that the function is bounded below.
It can solve problems having any number of variables, but it is
especially useful when the number of variables (n) is large.

	subroutine parameters:

	fx      On input, a rough estimate of the value of the
         	objective function at the solution; on output, the value
	        of the objective function at the solution        

	gx(n)   on output, the final value of the gradient

	x(n)    on input, an initial estimate of the solution; 
		on output, the computed solution.

	maxit   maximum number of inner iterations

	maxfc   maximum allowable number of function evaluations

	maxit   maximum number of inner iterations per step

	cgmaxit maximum number of inner iterations per step
		(preconditionned conjugate iteration)

	eta     severity of the linesearch

	xtol    desired accuracy for the solution x*

	stepmx  maximum allowable step in the linesearch

	accrcy  accuracy of computed function values

	print   determines quantity of printed output
		0 = none, 1 = one line per major iteration.

	info     ( 0 => normal return)
	         ( 1 => more than maxit iterations)
	         ( 2 => more than maxfun evaluations)
        	 ( 3 => line search failed to find
	         (          lower point (may not be serious)
	         (-1 => error in input parameters)

	fg_func:
		parameter: PDL(fx), PDL(gx), PDL(x)

=for example

	$x = random(5);
	$gx = $x->zeroes;
	$fx = rosen($x);
	
	$accrcy = pdl(1e-16);
	$xtol = pdl(1e-10);
	$stepmx =pdl(1);
	$eta =pdl(0.9);
	

	$info = pdl(long, 0);
	$print = pdl(long, 1);
	$maxit = pdl(long, 50);
	$cgmaxit = pdl(long, 50);
	$maxfc = pdl(long,250);


	sub fg_func{
		my ($f, $g, $x) = @_;
		$f .= rosen($x);
		$g .= rosen_grad($x);
	}
	lmqn($fx, $gx, $x, $maxit, $maxfc, $cgmaxit, $xtol, $accrcy, $eta, $stepmx, $print, $info,\&fg_func);




=for bad

lmqn ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*lmqn = \&PDL::lmqn;





=head2 lmqnbc

=for sig

  Signature: ([io,phys]fx();[io,phys]gx(n);[io,phys]x(n);[phys]bound(n,m=2);int [io,phys]maxit();int [io,phys]maxfc();int [phys]cgmaxit();[phys]xtol();[phys]accrcy();[phys]eta();[phys]stepmx();int [phys]print();int [io,phys]info(); SV* fg_func)



=for ref

This routine solves the optimization problem

   minimize     f(x)
      x
   subject to   low <= x <= up

where x is a vector of n real variables.  The method used is
a truncated-newton algorithm (see "newton-type minimization via
the lanczos algorithm" by s.g. nash (technical report 378, math.
The lanczos method" by s.g. nash (siam j. numer. anal. 21 (1984),
pp. 770-778).  This algorithm finds a local minimum of f(x).  It does
not assume that the function f is convex (and so cannot guarantee a
global solution), but does assume that the function is bounded below.
It can solve problems having any number of variables, but it is
especially useful when the number of variables (n) is large.

	subroutine parameters:

	fx      On input, a rough estimate of the value of the
         	objective function at the solution; on output, the value
	        of the objective function at the solution        

	gx(n)   on output, the final value of the gradient

	x(n)    on input, an initial estimate of the solution; 
		on output, the computed solution.

	bound(n,2)
		The lower and upper bounds on the variables.  if
           	there are no bounds on a particular variable, set
           	the bounds to -1.d38 and 1.d38, respectively.

	maxit   maximum number of inner iterations

	maxfc   maximum allowable number of function evaluations

	cgmaxit maximum number of inner iterations per step
		(preconditionned conjugate iteration)

	eta     severity of the linesearch

	xtol    desired accuracy for the solution x*

	stepmx  maximum allowable step in the linesearch

	accrcy  accuracy of computed function values

	print   determines quantity of printed output
		0 = none, 1 = one line per major iteration.

	info     ( 0 => normal return)
	         ( 1 => more than maxit iterations)
	         ( 2 => more than maxfun evaluations)
        	 ( 3 => line search failed to find
	         (          lower point (may not be serious)
	         (-1 => error in input parameters)

	fg_func:
		parameter: PDL(fx), PDL(gx), PDL(x)

=for example

	$x = random(5);
	$gx = $x->zeroes;
	$fx = rosen($x);
	$bounds =  zeroes(5,2);
	$bounds(,0).= -5;
	$bounds(,1).= 5;	
	
	$accrcy = pdl(1e-20);
	$xtol = pdl(1e-10);
	$stepmx =pdl(1);
	$eta = pdl(0.9);
	

	$info = pdl(long, 0);
	$print = pdl(long, 1);
	$maxit = pdl(long, 100);
	$maxfc = pdl(long,250);
	$cgmaxit = pdl(long, 50);


	sub fg_func{
		my ($f, $g, $x) = @_;
		$f .= rosen($x);
		$g .= rosen_grad($x);
	}
	lmqnbc($fx, $gx, $x, $bounds, $maxit, $maxfc, $cgmaxit, $xtol, $accrcy, $eta, $stepmx, $print, $info,\&fg_func);




=for bad

lmqnbc ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*lmqnbc = \&PDL::lmqnbc;





=head2 cgfam

=for sig

  Signature: ([io,phys]fx(); [io,phys]gx(n); [io,phys]x(n);int [io,phys]maxit();[phys]eps();[io,phys]xtol();[io,phys]gtol();int [phys]print(2);int [io,phys]info(); int [phys]method(); SV* fg_func)



=for ref

This subroutine solves the unconstrained minimization problem
 
		min f(x),    x= (x1,x2,...,xn),

using conjugate gradient methods, as described in the paper:
gilbert, j.c. and nocedal, j. (1992). "global convergence properties 
of conjugate gradient methods", siam journal on optimization, vol. 2,
pp. 21-42. 
 
 
      where
 
     fx      is a double precision variable. before initial entry and on
             a re-entry with info=1, it must be set by the user to
             contain the value of the function f at the point x.
 
     gx      is a double precision array of length n. before initial
             entry and on a re-entry with info=1, it must be set by
             the user to contain the components of the gradient g at
             the point x.
     x       on initial entry, it must be set by the user to the values
             of the initial estimate of the solution vector. 
	     on exit with info=0, it contains the values of the variables 
	     at the best point found (usually a solution).
 
     maxit   maximum number of iterations.
     
     eps     is a positive double precision variable that must be set by
             the user, and determines the accuracy with which the solution
             is to be found. the subroutine terminates when

                         ||g|| < eps max(1,||x||),

             where ||.|| denotes the euclidean norm.
 
     xtol    is a  positive double precision variable that must be set by
             the user to an estimate of the machine precision (e.g.
             10**(-16) on a sun station 3/60). the line search routine will
             terminate if the relative width of the interval of uncertainty
             is less than xtol.

     gtol    is a double precision variable which controls the accuracy of 
     	     the line search routine mcsrch. if the function and gradient 
             evaluations are inexpensive with respect to the cost of the 
	     iteration (which is sometimes the case when solving very large 
	     problems) it may be advantageous to set gtol to a small value. 
	     A typical small value is 0.1. It's set to 0.9 if gtol < 1.d-04.  
	     restriction: gtol should be greater than 1.d-04.

     print   frequency and type of printing
              iprint(1) < 0 : no output is generated
              iprint(1) = 0 : output only at first and last iteration
              iprint(1) > 0 : output every iprint(1) iterations
              iprint(2)     : specifies the type of output generated;
                              the larger the value (between 0 and 3),
                              the more information
              iprint(2) = 0 : no additional information printed
		iprint(2) = 1 : initial x and gradient vectors printed
		iprint(2) = 2 : x vector printed every iteration
		iprint(2) = 3 : x vector and gradient vector printed 
				every iteration 
    info     controls termination of code, and return to main
               program to evaluate function and gradient
               info = -3 : improper input parameters
               info = -2 : descent was not obtained
               info = -1 : line search failure
               info =  0 : initial entry or 
                            successful termination without error   
               info = 1 : user canceled optimization (maximum iteration)
               info = 2 : user canceled optimization

     method =  1 : fletcher-reeves 
               2 : polak-ribiere
               3 : positive polak-ribiere ( beta=max{beta,0} )
 
     scalar fg_func: computes the value(fx) and gradient(gx)  of the function at x.
		param fx, gx, x
		return value
		 0  continue
		 1  last iteration

=for example

	$x = random(5);
	$gx = rosen_grad($x);
	$fx = rosen($x);
	
	$xtol = pdl(1e-10);
	$gtol = pdl(0.9);
	$eps = pdl(1e-10);
	$print = ones(2);
	$maxit = pdl(long, 200);
	$info = pdl(long,0);

	sub fg_func{
		my ($f, $g, $x) = @_;
		$f .= rosen($x);
		$g .= rosen_grad($x);
		return 0;		
	}
	cgfam($fx, $gx, $x, $maxit, $eps, $xtol, $gtol,$print,$info,1,\&fg_func);



=for bad

cgfam ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgfam = \&PDL::cgfam;





=head2 hooke

=for sig

  Signature: ([io,phys]x(n);int [io,phys]maxit();[phys]rho();[phys]tol(); SV* hooke_func)



=for ref

Find a point X where the nonlinear function f(X) has a local
minimum.  X is an n-vector and f(X) is a scalar.  In mathematical 
notation  

	f: R^n -> R^1.  

The objective function f()
is not required to be continuous.  Nor does f() need to be
differentiable.  The program does not use or require
derivatives of f().

The software user supplies three things: a subroutine that
computes f(X), an initial "starting guess" of the minimum point
X, and values for the algorithm convergence parameters.  Then
the program searches for a local minimum, beginning from the
starting guess, using the Direct Search algorithm of Hooke and
Jeeves.

rho controls convergence :

The algorithm works by taking "steps" from one estimate of 
a minimum, to another (hopefully better) estimate.  Taking   
big steps gets to the minimum more quickly, at the risk of   
"stepping right over" an excellent point.  The stepsize is   
controlled by a user supplied parameter called rho.  At each 
iteration, the stepsize is multiplied by rho  (0 < rho < 1), 
so the stepsize is successively reduced.			   
Small values of rho correspond to big stepsize changes,    
which make the algorithm run more quickly.  However, there   
is a chance (especially with highly nonlinear functions)	   
that these big changes will accidentally overlook a	   
promising search vector, leading to nonconvergence.	   
Large values of rho correspond to small stepsize changes,  
which force the algorithm to carefully examine nearby points 
instead of optimistically forging ahead.	This improves the  
probability of convergence.				   
The stepsize is reduced until it is equal to (or smaller   
than) tol.  So the number of iterations performed by	   
Hooke-Jeeves is determined by rho and tol:		   

    rho**(number_of_iterations) = tol		   

In general it is a good idea to set rho to an aggressively 
small value like 0.5 (hoping for fast convergence).  Then,   
if the user suspects that the reported minimum is incorrect  
(or perhaps not accurate enough), the program can be run	   
again with a larger value of rho such as 0.85, using the	   
result of the first minimization as the starting guess to    
begin the second minimization.				   




     x:		   On entry this is the user-supplied guess at the minimum.
     		   On exit this is the location of  the local minimum,
     		   calculated by the program    

     maxit	   On entry, a rarely used, halting    
		   criterion.  If the algorithm uses >= maxit    
		   iterations, halt.
		   On exit number of iteration.

     rho	   This is a user-supplied convergence 
		   parameter (more detail above), which should be  
		   set to a value between 0.0 and 1.0.	Larger	   
		   values of rho give greater probability of	   
		   convergence on highly nonlinear functions, at a 
		   cost of more function evaluations.  Smaller	   
		   values of rho reduces the number of evaluations 
		   (and the program running time), but increases   
		   the risk of nonconvergence.	See below.	   

     tol	   This is the criterion for halting   
		   the search for a minimum.  When the algorithm   
		   begins to make less and less progress on each   
		   iteration, it checks the halting criterion: if  
		   the stepsize is below tol, terminate the    
		   iteration and return the current best estimate  
		   of the minimum.  Larger values of tol (such 
		   as 1.0e-4) give quicker running time, but a	   
		   less accurate estimate of the minimum.  Smaller 
		   values of tol (such as 1.0e-7) give longer  
		   running time, but a more accurate estimate of   
		   the minimum. 				   
   
     func	   objective function to be minimized.
		   scalar double fun ($x(n))

=for example

	$x = random(2);
	sub test{
		my $a = shift;
		rosen($a)->sclr;
	}
	$rho = pdl(0.5);
	$tol = pdl(1e-7);
	$maxit =pdl(long, 500);
	$x->hooke($maxit, $rho,$tol,\&test);
	print "Minimum found at $x in $maxit iteration(s)";



=for bad

hooke ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*hooke = \&PDL::hooke;





=head2 gencan

=for sig

  Signature: ([io,phys]fx();[io,phys]gx(n);[io,phys]x(n);[phys]bound(n,m=2);[phys]fmin();int [phys]maxit();int [phys]maxfc();
		int [phys]nearlyq();int [phys]gtype();int [phys]htvtype();int [phys]trtype();int [phys]fmaxit();int [phys]gmaxit();
		int [phys]interpmaxit();int [phys]cgstop();int [phys]cgmaxit();int [phys]qmpmaxit();
		[phys]ftol();[phys]epsgpen();[phys]epsgpsn();[phys]cggtol();[phys]cgitol();[phys]cgftol();
		[phys]qmptol();[phys]delta();[phys]eta();[phys]delmin();
		[phys]lammin();[phys]lammax();[phys]theta();[phys]gamma();[phys]beta();
		[phys]sigma1();[phys]sigma2();[phys]nint();[phys]next();
		[phys]sterel();[phys]steabs();[phys]epsrel();[phys]epsabs();[phys]infty();
		[o,phys]gpeucn2();[o,phys]gpsupn();int [o,phys]iter();int [o,phys]fcnt();int [o,phys]gcnt();int [o,phys]cgcnt();
		int [o,phys]spgiter();int [o,phys] spgfcnt();int [o,phys]tniter();int [o,phys]tnfcnt();int [o,phys]tnstpcnt();
		int [o,phys]tnintcnt();int [o,phys] tnexgcnt();int [o,phys]tnexbcnt();int [o,phys]tnintfe();int [o,phys]tnexgfe();int [o,phys]tnexbfe();
		int [phys]print(p);int [phys]ncomp();int [io,phys]info(); SV* f_func; SV* g_func; SV* h_func)



=for ref

Solves the box-constrained minimization problem

		Minimize f(x)
		subject to l \leq x \leq u

using a method described in
E. G. Birgin and J. M. Martinez, "Large-scale active-set
box-constrained optimization method with spectral projected
gradients", Computational Optimization and
Applications 23, 101-125 (2002).

Subroutines evalf and evalg must be supplied by the user to
evaluate the function f and its gradient, respectively. The
calling sequences are

	inform evalf(f, x)

	inform evalg(g, x)

where x is the point where the function (the gradient) must be
evaluated, n is the number of variables and f (g) is the
functional value (the gradient vector). The real parameters
x, f, g must be double precision.

A subroutine evalhd to compute the Hessian times vector products
is optional. If this subroutine is not provided an incremental
quotients version will be used instead. The calling sequence of
this subroutine should be

	inform	call evalhd(hu, x, u, ind)

where x is the point where the approx-Hessian is being considered,
u is the vector which should be
multiplied by the approx-Hessian H and hu is the vector where the
product should be placed. The information about the matrix H must
be passed to evalhd by means of common declarations. The necessary
computations must be done in evalg. The real parameters x, u, hu
must be double precision.

This subroutine must be coded by the user, taking into account
that n is the number of variables of the problem and that hu must
be the product H u. Moreover, you must assume, when you code evalhd,
that only size(ind) components of u are nonnull and that ind is the set
of indices of those components. In other words, you must write
evalhd in such a way that hu is the vector whose i-th entry is

               hu(i) = \Sum_{j=1}^{nind} H_{i,ind(j)} u_ind(j)

Moreover, the only components of hu that you need to compute are
those which corresponds to the indices ind(1),...,ind(nind).
However, observe that you must assume that, in u, the whole
vector is present, with its n components, even the zeroes. So,
if you decide to code evalhd without taking into account the
presence of ind and nind, you can do it. A final observation:
probably, if nind is close to n, it is not worthwhile to use ind,
due to the cost of accessing the correct indices. If you want,
you can test, within your evalhd, if (say) nind > n/2, and, in
this case use a straightforward scalar product for the components
of hu.

Example: Suppose that the matrix H is full. The main steps of
evalhd could be:

          do i= 1, nind
              indi= ind(i)
              hu(indi)= 0.0d0
              do j= 1, nind
                  indj= ind(j)
                  hu(indi)= hu(indi) + H(indi,indj) * u(indj)
              end do
          end do


     On Entry

     x    double precision x(n)
          initial estimate to the solution

     bounds(n,2)
          lower bounds and upper bounds

     epsgpen double precision
          small positive number for declaring convergence when the
          euclidian norm of the projected gradient is less than
          or equal to epsgpen

          RECOMMENDED: epsgpen = 1.0d-5

     epsgpsn double precision
          small positive number for declaring convergence when the
          infinite norm of the projected gradient is less than
          or equal to epsgpsn

          RECOMMENDED: epsgpsn = 1.0d-5

     ftol double precision
          'lack of enough progress' measure. The algorithm stops by
          'lack of enough progress' when f(x_k) - f(x_{k+1}) <=
          ftol * max { f(x_j)-f(x_{j+1}, j<k} during fmaxit
          consecutive iterations. This stopping criterion may be
          inhibited setting ftol = 0. We recommend, preliminary, to
          set ftol = 0.01 and fmaxit = 5

          RECOMMENDED: ftol = 1.0d-2

     fmaxit integer
          see the meaning of ftol, above

          RECOMMENDED: fmaxit = 5

     gmaxit integer
          If the order of the euclidian-norm of the continuous projected
          gradient did not change during gmaxit consecutive iterations
          the execution stops. Recommended: gmaxit= 10. In any case
          gmaxit must be greater than or equal to 1

          RECOMMENDED: gmaxit = 10

     fmin double precision
          function value for the stopping criteria f <= fmin

          RECOMMENDED: fmin = -1.0d+99 (inhibited)

     maxit integer
          maximum number of iterations allowed

          RECOMMENDED: maxit = 1000

     maxfc integer
          maximum number of funtion evaluations allowed

          RECOMMENDED: maxfc = 5000

     delta
          initial trust-region radius. Default max{0.1||x||,0.1} is set
          if you set delta < 0. Otherwise, the parameters delta
          will be the ones set by the user.

          RECOMMENDED: delta = -1

     cgmaxit integer
          maximum number of iterations allowed for the cg subalgorithm

          Default values for this parameter and the previous one are
          0.1 and 10 * log (number of free variables). Default values
          are taken if you set ucgeps < 0 and cgmaxit < 0,
          respectively. Otherwise, the parameters ucgeps and cgmaxit
          will be the ones set by the user

          RECOMMENDED: cgmaxit = -1

     cgstop, cggtol double precision
          cgstop means cunjugate gradient stopping criterion relation, and
          cggtol means conjugate gradients projected gradient final norm.
          Both are related to a stopping criterion of conjugate gradients.
          This stopping criterion depends on the norm of the residual
          of the linear system. The norm of the this residual should be
          less or equal than a 'small'quantity which decreases as we are
          approximating the solution of the minimization problem (near the
          solution, better the truncated-Newton direction we aim). Then, the
          log of the required precision requested to conjugate gradient has
          a linear dependence on the log of the norm of the projected
          gradient. This linear relation uses the squared euclidian-norm
          of the projected gradient if cgstop = 1 and uses the sup-norm if
          cgstop = 2. In adition, the precision required to CG is equal to
          cgitol (conjugate gradient initial epsilon) at x0 and cgftol
          (conjugate gradient final epsilon) when the euclidian- or sup-norm
          of the projected gradient is equal to cggtol (conjugate gradients
          projected gradient final norm) which is an estimation of the value
          of the euclidian- or sup-norm of the projected gradient at the
          solution.

          RECOMMENDED: cgstop = 1, cggtol = epsgpen; or
                       cgstop = 2, cggtol = epsgpsn.

     cgitol, cgftol double precision
          small positive numbers for declaring convergence of the
          conjugate gradient subalgorithm when
          ||r||_2 < cgeps * ||rhs||_2, where r is the residual and
          rhs is the right hand side of the linear system, i.e., cg
          stops when the relative error of the solution is smaller
          that cgeps.

          cgeps varies from cgitol to cgftol in such a way that, depending
          on cgstop (see above),

          i) log10(cgeps^2) depends linearly on log10(||g_P(x)||_2^2)
          which varies from ||g_P(x_0)||_2^2 to epsgpen^2; or

          ii) log10(cgeps) depends linearly on log10(||g_P(x)||_inf)
          which varies from ||g_P(x_0)||_inf to epsgpsn.

          RECOMMENDED: cgitol = 1.0d-1, cgftol = 1.0d-5

     qmptol double precision
          see below

     qmpmaxit integer
          This and the previous one parameter are used for a stopping
          criterion of the conjugate gradient subalgorithm. If the
          progress in the quadratic model is less or equal than a
          fraction of the best progress ( qmptol * bestprog ) during
          qmpmaxit consecutive iterations then CG is stopped by not
          enough progress of the quadratic model.

          RECOMMENDED: qmptol = 1.0d-4, qmpmaxit = 5

     nearlyq logical
          if function f is (nearly) quadratic, use the option
          nearlyq = 0 Otherwise, keep the default option.

          if, at an iteration of CG we find a direction d such
          that d^T H d <= 0 then we take the following decision:

          (i) if nearlyq = 1 then take direction d and try to
          go to the boundary chosing the best point among the two
          point at the boundary and the current point.

          (ii) if nearlyq = 0 then we stop at the current point.

          RECOMMENDED: nearlyq = 0

     gtype integer
          type of gradient calculation
          gtype = 0 means user suplied evalg subroutine,
          gtype = 1 means central diference approximation.

          RECOMMENDED: gtype = 0

          (provided you have the evalg subroutine)

     htvtype integer
          type of gradient calculation
          htvtype = 0 means user suplied evalhd subroutine,
          htvtype = 1 means incremental quotients approximation.

          RECOMMENDED: htvtype = 1

          (you take some risk using this option but, unless you have
          a good evalhd subroutine, incremental quotients is a very
          cheap option)

     trtype integer
          type of trust-region radius
          trtype = 0 means 2-norm trust-region
          trtype = 1 means infinite-norm trust-region

          RECOMMENDED: trtype = 0

     print(0) integer
          commands printing. Nothing is printed if print < 0.
          If print = 0, only initial and final information is printed.
          If print > 0, information is printed every print iterations.
          Exhaustive printing when print > 0 is commanded by print(1).

          RECOMMENDED: print(0) = 1

     print(1) integer
          When print(0) > 0, detailed printing can be required setting
          print(1) = 1.

          RECOMMENDED: print(1) = 1

     eta  double precision
          constant for deciding abandon the current face or not
          We abandon the current face if the norm of the internal
          gradient (here, internal components of the continuous
          projected gradient) is smaller than (1-eta) times the
          norm of the continuous projected gradient. Using eta=0.9
          is a rather conservative strategy in the sense that
          internal iterations are preferred over SPG iterations.

          RECOMMENDED: eta = 0.9

     delmin double precision
          minimum 'trust region' to compute the Truncated Newton
          direction

          RECOMMENDED: delmin = 0.1

     lammin, lammax double precision
          The spectral steplength, called lambda, is projected
          inside the box [lammin,lammax]

          RECOMMENDED: lammin = 10^{-10} and lammax = 10^{10}

     theta double precision
          constant for the angle condition, i.e., at iteration k
          we need a direction d_k such that
          <g_k,d_k> <= -theta ||g||_2 ||d_k||_2,
          where g_k is \nabla f(x_k)

          RECOMMENDED: theta = 10^{-6}

     gamma double precision
          constant for the Armijo crtierion
          f(x + alpha d) <= f(x) + gamma * alpha * <\nabla f(x),d>

          RECOMMENDED: gamma = 10^{-4}

     beta double precision
          constant for the beta condition
          <d_k, g(x_k + d_k)>  .ge.  beta * <d_k,g_k>
          if (x_k + d_k) satisfies the Armijo condition but does not
          satisfy the beta condition then the point is accepted, but
          if it satisfied the Armijo condition and also satisfies the
          beta condition then we know that there is the possibility
          for a succesful extrapolation

          RECOMMENDED: beta = 0.5

     sigma1, sigma2 double precision
          constant for the safeguarded interpolation
          if alpha_new \notin [sigma1, sigma*alpha] then we take
          alpha_new = alpha / nint

          RECOMMENDED: sigma1 = 0.1 and sigma2 = 0.9

     nint double precision
          constant for the interpolation. See the description of
          sigma1 and sigma2 above. Sometimes we take as a new trial
          step the previous one divided by nint

          RECOMMENDED: nint = 2.0

     next double precision
          constant for the extrapolation
          when extrapolating we try alpha_new = alpha * next

          RECOMMENDED: next = 2.0

     interpmaxit integer
          constant for testing if, after having made at least interpmaxit
          interpolations, the steplength is too small. In that case
          failure of the line search is declared (may be the direction
          is not a descent direction due to an error in the gradient
          calculations)

          RECOMMENDED: interpmaxit = 4

          (use interpmaxit > maxfc for inhibit this stopping criterion)

     ncomp integer
          this constant is just for printing. In a detailed printing
          option, ncomp component of the actual point will be printed

          RECOMMENDED: ncomp = 5

     sterel, steabs double precision
          this constants mean a 'relative small number' and 'an
          absolute small number' for the increments in finite
          difference approximations of derivatives

          RECOMMENDED: epsrel = 10^{-7}, epsabs = 10^{-10}

     epsrel, epsabs, infty  double precision
          this constants mean a 'relative small number', 'an
          absolute small number', and 'infinite or a very big
          number'. Basically, a quantity A is considered negligeble
          with respect to another quantity B if
          |A| < max ( epsrel * |B|, epsabs )

          RECOMMENDED: epsrel = 10^{-10}, epsabs = 10^{-20} and
          infty = 10^{+20}

     On Return

     x    double precision x(n)
          final estimation to the solution

     f    double precision
          function value at the final estimation

     g    double precision g(n)
          gradient at the final estimation

     gpeucn2 double precision
          squared 2-norm of the continuous projected
          gradient g_p at the final estimation (||g_p||_2^2)

     gpsupn double precision
          ||g_p||_inf at the final estimation

     iter integer
          number of iterations

     fcnt integer
          number of function evaluations

     gcnt integer
          number of gradient evaluations

     cgcnt integer
          number of conjugate gradient iterations

     spgiter integer
          number of SPG iterations

     spgfcnt integer
          number of function evaluations in SPG-directions line searches

     tniter integer
          number of Truncated Newton iterations

     tnfcnt integer
          number of function evaluations in TN-directions line searches

     tnintcnt integer
          number of times a backtracking in a TN-direction was needed

     tnexgcnt integer
          number of times an extrapolation in a TN-direction was
          successfull in decreass the function value

     tnexbcnt integer
          number of times an extrapolation was aborted in the first
          extrapolated point by augment of the function value

     info
          This output parameter tells what happened in this
          subroutine, according to the following conventions:

          0= convergence with small euclidian-norm of the
             projected gradient (smaller than epsgpen);

          1= convergence with small infinite-norm of the
             projected gradient (smaller than epsgpsn);

          2= the algorithm stopped by 'lack of enough progress',
             that means that f(x_k) - f(x_{k+1}) <=
             ftol * max { f(x_j)-f(x_{j+1}, j<k} during fmaxit
             consecutive iterations;

          3= the algorithm stopped because the order of the euclidian-
             norm of the continuous projected gradient did not change
             during gmaxit consecutive iterations. Probably, we
             are asking for an exagerately small norm of continuous
             projected gradient for declaring convergence;

          4= the algorithm stopped because the functional value
             is very small (f <= fmin);

          6= too small step in a line search. After having made at
             least interpmaxit interpolations, the steplength becames
             small. 'small steplength' means that we are at point
             x with direction d and step alpha, and

             alpha * ||d||_infty < max(epsabs, epsrel * ||x||_infty).

             In that case failure of the line search is declared
             (may be the direction is not a descent direction
             due to an error in the gradient calculations). Use
             interpmaxit > maxfc for inhibit this criterion;

          7= it was achieved the maximum allowed number of
             iterations (maxit);

          8= it was achieved the maximum allowed number of
             function evaluations (maxfc);

          9= error in evalf subroutine;

         10= error in evalg subroutine;

         11= error in evalhd subroutine.

=for example

	$x = random(50);
	$gx = $x->zeroes;
	$fx = pdl(0);
	
	$print = pdl(long,[1,0]);
	$info = pdl(long,0);
	$bounds = zeroes(50,2);
	$bounds(,0).=-5;
	$bounds(,1).=5;

	sub f_func{
		my ($fx, $x) = @_;
		$fx .= rosen($x);
		return 0;	
	}
	sub g_func{
		my ($gx, $x) = @_;
		$gx .= rosen_grad($x);		
		return 0;	
	}
	sub h_func{
		my ($hx, $x, $d, $ind) = @_;
		$hx .= rosen_hess($x,1) x $d;
		return 0;	
	}
	gencan($fx, $gx, $x, $bounds, -1e308, 200, 1000,
	1, 0, 0, 0, 5, 10, 5, 1, -1, 5,
	0, 1e-10, 1e-10, 1e-8, 0.1, 1e-8, 1e-8, 
	-1, 0.9, 0.1,
	1e+40, 1e-40, 1e-6, 0.0001, 0.5, 0.1,0.9,
	2, 2, 1e-10, 1e-99, 1e-30, 1e-99, 1e+308,
	($gpeucn2=null), ($gpsupn=null), ($iter=null), ($fcnt=null), 
	($gcnt=null), ($cgcnt=null), ($spgiter=null), ($spgfcnt=null),
	($tniter=null), ($tnfcnt=null), ($tnstpcnt=null), ($tnintcnt=null), ($tnexgcnt=null), ($tnexbcnt=null),
	($tnintfe=null), ($tnexgfe=null), ($tnexbfe=null),	
	$print,5, $info,\&f_func,\&g_func, \&h_func);



=for bad

gencan ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*gencan = \&PDL::gencan;





=head2 sgencan

=for sig

  Signature: ([io,phys]fx();[io,phys]gx(n);[io,phys]x(n);[phys]bound(n,m=2);int [io,phys]maxit();int [io,phys]maxfc();
		int [phys]nearlyq();int [phys]gtype();int [phys]htvtype();int [phys]trtype();int [phys]fmaxit();int [phys]gmaxit();
		int [phys]interpmaxit();int [phys]cgstop();int [phys]cgmaxit();int [phys]qmpmaxit();
		[phys]ftol();[phys]epsgpen();[phys]epsgpsn();[phys]cggtol();[phys]cgitol();[phys]cgftol();
		[phys]qmptol();[phys]delta();[phys]eta();[phys]delmin();
		int [phys]print(p);int [io,phys]info(); SV* f_func; SV* g_func; SV* h_func)



=for ref

Solves the box-constrained minimization problem

		Minimize f(x)
		subject to l \leq x \leq u

using a method described in
E. G. Birgin and J. M. Martinez, "Large-scale active-set
box-constrained optimization method with spectral projected
gradients", Computational Optimization and
Applications 23, 101-125 (2002).

This is the simplified version of gencan.
Subroutines evalf and evalg must be supplied by the user to
evaluate the function f and its gradient, respectively. The
calling sequences are

	inform evalf(f, x)

	inform evalg(g, x)

where x is the point where the function (the gradient) must be
evaluated, n is the number of variables and f (g) is the
functional value (the gradient vector). The real parameters
x, f, g must be double precision.

A subroutine evalhd to compute the Hessian times vector products
is optional. If this subroutine is not provided an incremental
quotients version will be used instead. The calling sequence of
this subroutine should be

	inform	call evalhd(hu, x, u, ind)

        where x is the point where the approx-Hessian is being considered,
        u is the vector which should be multiplied by the approx-Hessian H
	and hu is the vector where the product should be placed.

The information about the matrix H must
be passed to evalhd by means of common declarations. The necessary
computations must be done in evalg. The real parameters x, u, hu
must be double precision.

This subroutine must be coded by the user, taking into account
that n is the number of variables of the problem and that hu must
be the product H u. Moreover, you must assume, when you code evalhd,
that only size(ind) components of u are nonnull and that ind is the set
of indices of those components. In other words, you must write
evalhd in such a way that hu is the vector whose i-th entry is

               hu(i) = \Sum_{j=1}^{nind} H_{i,ind(j)} u_ind(j)

Moreover, the only components of hu that you need to compute are
those which corresponds to the indices ind(1),...,ind(nind).
However, observe that you must assume that, in u, the whole
vector is present, with its n components, even the zeroes. So,
if you decide to code evalhd without taking into account the
presence of ind and nind, you can do it. A final observation:
probably, if nind is close to n, it is not worthwhile to use ind,
due to the cost of accessing the correct indices. If you want,
you can test, within your evalhd, if (say) nind > n/2, and, in
this case use a straightforward scalar product for the components
of hu.

Example: Suppose that the matrix H is full. The main steps of
evalhd could be:

          do i= 1, nind
              indi= ind(i)
              hu(indi)= 0.0d0
              do j= 1, nind
                  indj= ind(j)
                  hu(indi)= hu(indi) + H(indi,indj) * u(indj)
              end do
          end do


     On Entry

     x    double precision x(n)
          initial estimate to the solution

     bounds(n,2)
          lower bounds and upper bounds

     epsgpen double precision
          small positive number for declaring convergence when the
          euclidian norm of the projected gradient is less than
          or equal to epsgpen

          RECOMMENDED: epsgpen = 1.0d-5

     epsgpsn double precision
          small positive number for declaring convergence when the
          infinite norm of the projected gradient is less than
          or equal to epsgpsn

          RECOMMENDED: epsgpsn = 1.0d-5

     ftol double precision
          'lack of enough progress' measure. The algorithm stops by
          'lack of enough progress' when f(x_k) - f(x_{k+1}) <=
          ftol * max { f(x_j)-f(x_{j+1}, j<k} during fmaxit
          consecutive iterations. This stopping criterion may be
          inhibited setting ftol = 0. We recommend, preliminary, to
          set ftol = 0.01 and fmaxit = 5

          RECOMMENDED: ftol = 1.0d-2

     fmaxit integer
          see the meaning of ftol, above

          RECOMMENDED: fmaxit = 5

     gmaxit integer
          If the order of the euclidian-norm of the continuous projected
          gradient did not change during gmaxit consecutive iterations
          the execution stops. Recommended: gmaxit= 10. In any case
          gmaxit must be greater than or equal to 1

          RECOMMENDED: gmaxit = 10

     fmin double precision
          function value for the stopping criteria f <= fmin

          RECOMMENDED: fmin = -1.0d+99 (inhibited)

     maxit integer
          maximum number of iterations allowed

          RECOMMENDED: maxit = 1000

     maxfc integer
          maximum number of funtion evaluations allowed

          RECOMMENDED: maxfc = 5000

     delta
          initial trust-region radius. Default max{0.1||x||,0.1} is set
          if you set delta < 0. Otherwise, the parameters delta
          will be the ones set by the user.

          RECOMMENDED: delta = -1

     cgmaxit integer
          maximum number of iterations allowed for the cg subalgorithm

          Default values for this parameter and the previous one are
          0.1 and 10 * log (number of free variables). Default values
          are taken if you set ucgeps < 0 and cgmaxit < 0,
          respectively. Otherwise, the parameters ucgeps and cgmaxit
          will be the ones set by the user

          RECOMMENDED: cgmaxit = -1

     cgstop, cggtol double precision
          cgstop means cunjugate gradient stopping criterion relation, and
          cggtol means conjugate gradients projected gradient final norm.
          Both are related to a stopping criterion of conjugate gradients.
          This stopping criterion depends on the norm of the residual
          of the linear system. The norm of the this residual should be
          less or equal than a 'small'quantity which decreases as we are
          approximating the solution of the minimization problem (near the
          solution, better the truncated-Newton direction we aim). Then, the
          log of the required precision requested to conjugate gradient has
          a linear dependence on the log of the norm of the projected
          gradient. This linear relation uses the squared euclidian-norm
          of the projected gradient if cgstop = 1 and uses the sup-norm if
          cgstop = 2. In adition, the precision required to CG is equal to
          cgitol (conjugate gradient initial epsilon) at x0 and cgftol
          (conjugate gradient final epsilon) when the euclidian- or sup-norm
          of the projected gradient is equal to cggtol (conjugate gradients
          projected gradient final norm) which is an estimation of the value
          of the euclidian- or sup-norm of the projected gradient at the
          solution.

          RECOMMENDED: cgstop = 1, cggtol = epsgpen; or
                       cgstop = 2, cggtol = epsgpsn.

     cgitol, cgftol double precision
          small positive numbers for declaring convergence of the
          conjugate gradient subalgorithm when
          ||r||_2 < cgeps * ||rhs||_2, where r is the residual and
          rhs is the right hand side of the linear system, i.e., cg
          stops when the relative error of the solution is smaller
          that cgeps.

          cgeps varies from cgitol to cgftol in such a way that, depending
          on cgstop (see above),

          i) log10(cgeps^2) depends linearly on log10(||g_P(x)||_2^2)
          which varies from ||g_P(x_0)||_2^2 to epsgpen^2; or

          ii) log10(cgeps) depends linearly on log10(||g_P(x)||_inf)
          which varies from ||g_P(x_0)||_inf to epsgpsn.

          RECOMMENDED: cgitol = 1.0d-1, cgftol = 1.0d-5

     qmptol double precision
          see below

     qmpmaxit integer
          This and the previous one parameter are used for a stopping
          criterion of the conjugate gradient subalgorithm. If the
          progress in the quadratic model is less or equal than a
          fraction of the best progress ( qmptol * bestprog ) during
          qmpmaxit consecutive iterations then CG is stopped by not
          enough progress of the quadratic model.

          RECOMMENDED: qmptol = 1.0d-4, qmpmaxit = 5

     nearlyq logical
          if function f is (nearly) quadratic, use the option
          nearlyq = 0 Otherwise, keep the default option.

          if, at an iteration of CG we find a direction d such
          that d^T H d <= 0 then we take the following decision:

          (i) if nearlyq = 1 then take direction d and try to
          go to the boundary chosing the best point among the two
          point at the boundary and the current point.

          (ii) if nearlyq = 0 then we stop at the current point.

          RECOMMENDED: nearlyq = 0

     gtype integer
          type of gradient calculation
          gtype = 0 means user suplied evalg subroutine,
          gtype = 1 means central diference approximation.

          RECOMMENDED: gtype = 0

          (provided you have the evalg subroutine)

     htvtype integer
          type of gradient calculation
          htvtype = 0 means user suplied evalhd subroutine,
          htvtype = 1 means incremental quotients approximation.

          RECOMMENDED: htvtype = 1

          (you take some risk using this option but, unless you have
          a good evalhd subroutine, incremental quotients is a very
          cheap option)

     trtype integer
          type of trust-region radius
          trtype = 0 means 2-norm trust-region
          trtype = 1 means infinite-norm trust-region

          RECOMMENDED: trtype = 0

     print(0) integer
          commands printing. Nothing is printed if print < 0.
          If print = 0, only initial and final information is printed.
          If print > 0, information is printed every print iterations.
          Exhaustive printing when print > 0 is commanded by print(1).

          RECOMMENDED: print(0) = 1

     print(1) integer
          When print(0) > 0, detailed printing can be required setting
          print(1) = 1.

          RECOMMENDED: print(1) = 1

     eta  double precision
          constant for deciding abandon the current face or not
          We abandon the current face if the norm of the internal
          gradient (here, internal components of the continuous
          projected gradient) is smaller than (1-eta) times the
          norm of the continuous projected gradient. Using eta=0.9
          is a rather conservative strategy in the sense that
          internal iterations are preferred over SPG iterations.

          RECOMMENDED: eta = 0.9

     delmin double precision
          minimum 'trust region' to compute the Truncated Newton
          direction

          RECOMMENDED: delmin = 0.1


     interpmaxit integer
          constant for testing if, after having made at least interpmaxit
          interpolations, the steplength is too small. In that case
          failure of the line search is declared (may be the direction
          is not a descent direction due to an error in the gradient
          calculations)

          RECOMMENDED: interpmaxit = 4

          (use interpmaxit > maxfc for inhibit this stopping criterion)


     On Return

     x    double precision x(n)
          final estimation to the solution

     f    double precision
          function value at the final estimation

     g    double precision g(n)
          gradient at the final estimation

     maxit
          number of iterations

     maxfc
          number of function evaluations

     info
          This output parameter tells what happened in this
          subroutine, according to the following conventions:

          0= convergence with small euclidian-norm of the
             projected gradient (smaller than epsgpen);

          1= convergence with small infinite-norm of the
             projected gradient (smaller than epsgpsn);

          2= the algorithm stopped by 'lack of enough progress',
             that means that f(x_k) - f(x_{k+1}) <=
             ftol * max { f(x_j)-f(x_{j+1}, j<k} during fmaxit
             consecutive iterations;

          3= the algorithm stopped because the order of the euclidian-
             norm of the continuous projected gradient did not change
             during gmaxit consecutive iterations. Probably, we
             are asking for an exagerately small norm of continuous
             projected gradient for declaring convergence;

          4= the algorithm stopped because the functional value
             is very small (f <= fmin);

          6= too small step in a line search. After having made at
             least interpmaxit interpolations, the steplength becames
             small. 'small steplength' means that we are at point
             x with direction d and step alpha, and

             alpha * ||d||_infty < max(epsabs, epsrel * ||x||_infty).

             In that case failure of the line search is declared
             (may be the direction is not a descent direction
             due to an error in the gradient calculations). Use
             interpmaxit > maxfc for inhibit this criterion;

          7= it was achieved the maximum allowed number of
             iterations (maxit);

          8= it was achieved the maximum allowed number of
             function evaluations (maxfc);

          9= error in evalf subroutine;

         10= error in evalg subroutine;

         11= error in evalhd subroutine.

=for example

	$x = random(5);
	$gx = $x->zeroes;
	$fx = pdl(0);
	
	$print = pdl(long,[1,0]);
	$maxit = pdl(long, 200);
	$maxfc = pdl(long, 1000);
	$info = pdl(long,0);
	$bounds = zeroes(5,2);
	$bounds(,0).=-5;
	$bounds(,1).=5;

	sub f_func{
		my ($fx, $x) = @_;
		$fx .= rosen($x);
		return 0;
	}
	sub g_func{
		my ($gx, $x) = @_;
		$gx .= rosen_grad($x);		
		return 0;	
	}
	sub h_func{
		my ($hx, $x, $d, $ind) = @_;
		$hx .= rosen_hess($x,1) x $d;
		return 0;
	}
	sgencan($fx, $gx, $x, $bounds, $maxit, $maxfc,
	1, 0, 0, 0, 5, 10, 5, 1, -1, 5,
	0, 1e-8, 1e-10, 1e-5, 0.1, 1e-5, 1e-5, 
	-1, 0.9, 0.1,
	$print,$info,\&f_func,\&g_func, \&h_func);



=for bad

sgencan ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*sgencan = \&PDL::sgencan;





=head2 dhc

=for sig

  Signature: ([io,phys]xrandom(n,m);step(); xtol(); int print();[o]fx();[o]x(n); SV* dhc_func)



=for ref

Find a point X where the function dhc_func(X) has a global
minimum.  X is an n-vector and f(X) is a scalar.  In mathematical 
notation  

	f: R^n -> R^1.

using a method, dynamic hill climbing, described in
D. Yuret, "From Genetic Algorithms To Efficient Optimization",
A.I. Technical Report No. 1569 (1994).
(http://home.ku.edu.tr/~dyuret/pub/aitr1569.html).


      where
 
     fx:           On exit it contains the value of the function f at 
		   the point x.
     x:		   On exit this is the location of the global minimum,
     		   calculated by the program.
     xrandom:	   This is a user-supplied initial starting locations.
		   On exit there are locations of the minimums
		   calculated by the program.
     step:	   Initial step length.
     xtol:	   Step tolerance(minimum step size).
     print:	   if true print some information at each iteration
		   (each minimum).
     dhc_func:	   Objective function to be minimized.
		   If you need boundary conditions, put them in the 
		   objective function such that the optimizer gets 
		   bad values for points out of bounds.
		   scalar double dhc_func($x())

=for example

	# Local Optimization
	$randomx = grandom(2);
	sub test{
		my $a = shift;
		rosen($a)->sclr;
	}
	$step = pdl(1.0);
	$tol = pdl(1e-10);
	($fx ,  $ret) = dhc($randomx, $step, $tol,0,\&test);
	print "Minimum found ($fx) at $ret";

	# Try to solve
	# The SIAM 100-Digit Challenge problem 4 
	# see http://www-m8.ma.tum.de/m3/bornemann/challengebook/
	# result: -3.30686864747523728007611377089851565716648236
	$randomx = (random(2,100)-0.5)*2;
	sub test{
		my $x = shift;
		my $f = exp(sin(50*$x(0)))+sin(60*exp($x(1)))+ 
		sin(70*sin($x(0)))+sin(sin(80*$x(1)))-
                sin(10*($x(0)+$x(1)))+($x(0)**2+$x(1)**2)/4;
		$f->sclr;
	}
	$step = pdl(0.7);
	$tol = pdl(1e-8);
	($fx ,  $ret) = dhc($randomx, $step, $tol,0,\&test);
	print "Minimum found ($fx) at $ret";


=for bad

dhc ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*dhc = \&PDL::dhc;





=head2 de_opt

=for sig

  Signature: ([io,phys]x(n);int genmax();int seed();int strategy();
		int np();f();cr();inibound_l();inibound_u();int print();[o]fx();[o]cvar(); SV* de_func)



=for ref

Find a point X where the function de_func(X) has a global
minimum.  X is an n-vector and f(X) is a scalar. In mathematical 
notation  

	f: R^n -> R^1.

using a method described in
Storn, R. and Price, K., "Differential Evolution - a Simple and Efficient
Adaptive Scheme for Global Optimization over Continuous Spaces",
Technical Report TR-95-012, ICSI, March 1995.
(http://www.icsi.berkeley.edu/~storn/code.html)

Strategy:

	1:   "DE/best/1/exp",
        2:    "DE/rand/1/exp",
        3:    "DE/rand-to-best/1/exp",
        4:    "DE/best/2/exp",
        5:    "DE/rand/2/exp",
        6:    "DE/best/1/bin",
        7:    "DE/rand/1/bin",
        8:    "DE/rand-to-best/1/bin",
        9:    "DE/best/2/bin",
        10:    "DE/rand/2/bin"


	Choice of strategy
	We have tried to come up with a sensible naming-convention: DE/x/y/z
	DE :  stands for Differential Evolution
	x  :  a string which denotes the vector to be perturbed
	y  :  number of difference vectors taken for perturbation of x
	z  :  crossover method (exp = exponential, bin = binomial)

	There are some simple rules which are worth following:
	F is usually between 0.5 and 1 (in rare cases > 1
	CR is between 0 and 1 with 0., 0.3, 0.7 and 1. being worth to be tried first
	To start off NP = 10*D is a reasonable choice. Increase NP if misconvergence happens.
	If you increase NP, F usually has to be decreased
	When the DE/best... schemes fail DE/rand... usually works and vice versa


      where
 
     fx:           On exit it contains the value of the function f at 
		   the point x.
     x:		   On exit this is the location of the global minimum,
     		   calculated by the program.
     cvar:	   On exit it contains the value variance of the function f.
     strategy:	   Choice of strategy.
     seed:	   Random seed.
     genmax:	   Maximum number of generations.
     np:	   Population size.
     cr:	   Crossing over factor.
     f:		   Weight factor.
     inibound_l:   Lower parameter bound for init.
     inibound_u:   Upper parameter bound for init.
     print:	   if > 1 print some information at each 'print' generation
		   (minimum = 1).
     de_func:	   Objective function to be minimized.
		   If you need boundary conditions, put them in the 
		   objective function such that the optimizer gets 
		   bad values for points out of bounds.
		   scalar double de_func($x())

=for example

	# Try to solve
	# The SIAM 100-Digit Challenge problem 4 
	# see http://www-m8.ma.tum.de/m3/bornemann/challengebook/
	# result: -3.30686864747523728007611377089851565716648236
	use PDL::Opt::NonLinear;   

	$x = zeroes(2);
	$strategy = pdl(long,7);
	$np = pdl(long,50);
	$print = pdl(long,50);
	$inibound_l = pdl(-1.0);
	$inibound_h = pdl(1.0);
	$genmax = pdl(long,250);
	$seed = pdl(long,3);
	$f = pdl(0.9);
	$cr = pdl(0.9);

	sub test{
                my $x = shift;
                my ($x0, $y1);
		$x0 = PDL::Core::sclr_c($x(0));
		$y1 = PDL::Core::sclr_c($x(1));
		my $f = exp(sin(50*$x0))+sin(60*exp($y1))+ 
                sin(70*sin($x0))+sin(sin(80*$y1))-
                sin(10*($x0+$y1))+($x0**2+$y1**2)/4;
                $f;
	}
	($fx,$cvar)=de_opt($x, $genmax, $seed, $strategy, $np, 
		$f, $cr, $inibound_l, $inibound_h, 
		$print, \&test);

	print "Minimum found ($fx) at $x with variance $cvar\n";


=for bad

de_opt ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*de_opt = \&PDL::de_opt;





=head2 asa_opt

=for sig

  Signature: ([io,phys]x(n);int seed();inibound_l(n);inibound_u(n);
	int parameter_type(n); int limit(5); cost_param(4); temperature(3);
	int generic(10);resolution(n);coarse_resolution(n);
	quench_cost(); quench_param(n);int print();[o]fx();[o]tangents(n);[o]curvature(n,n);int [o]info(); SV* asa_func)



=for ref


This routine solves the optimization problem

   minimize     f(x)
      x
   subject to   low <= x <= up


It uses the Adaptive Simulated Annealing (ASA) method.
(see http://www.ingber.com/#ASA-CODE)

     where

     x 
	is a double precision array of dimension n.
	On entry x is an approximation to the solution.
	On exit x is the current approximation.

     seed
	random seed.

     inibound_l
	lower bound on x.
	
     inibound_u
	upper bound on x.

     parameter_type
	type of value of x
		-2 => real value, no reanneal
		-1 => real value
		 1 => integral value
		 2 => integral value, no reanneal

     limit
	limit(0) = Maximum_Cost_Repeat
	limit(1) = Number_Cost_Samples
	limit(2) = Limit_Acceptances
	limit(3) = Limit_Generated
	limit(4) = Limit_Invalid_Generated_States
	
     cost_param
	cost_param(0) = Accepted_To_Generated_Ratio
	cost_param(1) = Cost_Precision
	cost_parma(2) = Cost_Parameter_Scale_Ratio
	cost_parma(3) = Delta_X
	
     temperature
	temperature(0) = Initial_Parameter_Temperature
	temperature(1) = Temperature_Ratio_Scale
	temperature(2) = Temperature_Anneal_Scale

     generic
	generic(0) = Include_Integer_Parameters
	generic(1) = User_Initial_Parameters
	generic(2) = Sequential_Parameters
	generic(3) = Acceptance_Frequency_Modulus
	generic(4) = Generated_Frequency_Modulus
	generic(5) = Reanneal_Cost
	generic(6) = Reanneal_Parameters
	generic(7) = Queue_Size
	generic(8) = User_Tangents (not implemented)
	generic(9) = Curvature_0

     resolution
	On entry, array of resolutions used to compare
	the currently generated parameters to those in the queue.

     coarse_resolution
	On entry, array of resolutions used to resolve
	the values of generated parameters.

     quench_cost
	used to adaptively set the scale of the temperature schedule.

     quench_param
	used to adaptively set the scale of the temperature schedule.

     print
	 print = 0 no output is generated

     fx
	On final exit f is the value of the function at x.

     tangents
	On exit, it is the value of the tangents (gradient) at x.

     curvature
     	On exit, it is the value of the curvature (hessian) at x.

     info
     	On entry 0,
     	On exit, contain error code:
		NORMAL_EXIT		    => 0
		P_TEMP_TOO_SMALL	    => 1
		C_TEMP_TOO_SMALL	    => 2
		COST_REPEATING		    => 3
		TOO_MANY_INVALID_STATES	    => 4
		IMMEDIATE_EXIT		    => 5
		INVALID_USER_INPUT	    => 7
		INVALID_COST_FUNCTION	    => 8
		INVALID_COST_FUNCTION_DERIV => 9
		CALLOC_FAILED		    => -1



=for example

	# Try to solve
	# The SIAM 100-Digit Challenge problem 4 
	# see http://www-m8.ma.tum.de/m3/bornemann/challengebook/
	# result: -3.30686864747523728007611377089851565716648236
	use PDL::Opt::NonLinear;
	sub test{
                my $x = shift;
                my ($x0, $y1);
                $x0 = PDL::Core::sclr_c($x(0));
                $y1 = PDL::Core::sclr_c($x(1));
                my $f = exp(sin(50*$x0))+sin(60*exp($y1))+ 
                sin(70*sin($x0))+sin(sin(80*$y1))-
                sin(10*($x0+$y1))+($x0**2+$y1**2)/4;
                $f;
        }

	$bu = zeroes(2);
	$bl = zeroes(2);
	$bu .= 1;
	$bl .= -1;
	$seed = pdl(696969);
	$parameter = zeroes(long,2);
	$parameter .= -1;
	$qp = ones(2);
	$qc = pdl(1.0);
	$print = pdl(long,0);
	$seed = pdl(long, 696969);
	$limit = pdl(long,[5,10,1000,99999,1000]);
	$cost_param = pdl [1.e-4,1.e-18,1.0,0.001];
	# $temp = pdl [1.0,1.e-5,100.0]; for generic problem
	$temp = pdl [1.0,1.e-5,10000.0];
	$generic = pdl(long,[0,0,-1,100,10000,1,1,50,0,0]);
	$res = zeroes(2);
	$coarse = zeroes(2);

	$x = (random(2)-0.5)*2;
	asa_opt($x, ++$seed, $bl, $bu, $parameter, $limit, $cost_param, $temp,
		$generic, $res, $coarse, $qc, $qp, $print, \&test);

	# Local optimize now
	$rho = pdl(0.2);
	$tol = pdl(1e-10);
	$maxit =pdl(long, 500);
	$x->hooke($maxit, $rho,$tol,\&test);
	print "Minimum found ".test($x)." at $x in $maxit iteration(s)";



=for bad

asa_opt ignores the bad-value flag of the input piddles.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*asa_opt = \&PDL::asa_opt;



;


sub rosen{
	my $a = shift;
	sumover( 100 * ($a(1:) - $a(:-2)->power(2,0))**2 + (1-$a(:-2))**2);

}

sub optimize{
	my ($x, %opt) = @_;
	my ($function, %ret);

	$function = $opt{function} ? $opt{function} : 'lbfgs';
	$ret{fx} = pdl($x->type, 0);

	#TODO error, print

	if (substr($function,0,5) eq 'lbfgs' || 
		substr($function,0,4) eq 'lmqn' ||
		 $function eq 'cgfam'){
		barf "optimize: no evaluation function\n" 
			if ( (!defined $opt{fg_func}) && (!defined $opt{f_func}) && (!defined $opt{g_func}));
		if (!defined $opt{fg_func}){
			barf "optimize: no gradient evaluation function\n" unless defined $opt{g_func};
			barf "optimize: no evaluation function\n" unless defined $opt{f_func};
			$opt{fg_func} = sub {
				my ($fx, $gx, $x) = @_;
				$opt{f_func}($fx, $x);
				$opt{g_func}($gx, $x);
			};
		}
		if ($function eq 'lbfgs'){
			my ($diagco, $diag);
			$ret{gx} = $x->zeroes;
			$diag = $x->zeroes;		

			$opt{eps} = pdl(1e-16) unless defined $opt{eps};
			$opt{eta} = pdl(0.9) unless defined $opt{eta};
			$opt{gtol} = pdl(1e-10) unless defined $opt{gtol};
			$opt{'print'} = pdl(long,[-1,0])unless defined $opt{'print'};
			if ( ! ref $opt{'print'}){
				if ($opt{'print'} == -1){
					$opt{'print'} = pdl(long,[-1,0]);
				}
				elsif ($opt{'print'} == 0){
					$opt{'print'} = pdl(long,[$opt{'print'},0]);
				}
				else{
					$opt{'print'} = pdl(long,[$opt{'print'},0]);
				}
			}
			$ret{fcnt} = defined $opt{maxfc} ? pdl ($opt{maxfc}) : pdl(long , 100);
			$ret{iter} = defined $opt{maxit} ? pdl ($opt{maxit}) : pdl(long , 50);
			$ret{info} = pdl(long,0);
			$opt{'m'} = pdl(long , 10) unless defined $opt{'m'};
			if(defined $opt{d_func}){
				$opt{d_func}($diag, $x);
				$diagco= pdl(long,1);
			}
			else{
				$opt{d_func} = sub{};
				$diagco= pdl(long,0);
			}
			$opt{fg_func}($ret{fx}, $ret{gx}, $x);
			lbfgs($ret{fx}, $ret{gx}, $x, $diag, $diagco, $opt{'m'}, $ret{iter}, $ret{fcnt}, $opt{gtol}, $opt{eps}, $opt{eta},
			        $opt{'print'},$ret{info},$opt{fg_func},$opt{d_func});
		}
		elsif($function eq 'lbfgsb'){
			my ($iv, $v);
			$ret{gx} = $x->zeroes;
			
			#TODO: extract iv and v		
			if (defined $opt{bound}){
				barf "optimize: no bound type\n" unless defined $opt{tbound};
			}
			else{
				$opt{tbound} = zeroes(long, $x->dim(0));
				$opt{bound} = zeroes($x->type, $x->dim(0),2);
			}
			$opt{eta} = pdl(0.9) unless defined $opt{eta};
			$opt{gtol} = pdl(1e-10) unless defined $opt{gtol};
			$opt{factr} = pdl(100) unless defined $opt{factr};
			$opt{'print'} = pdl(long,[-1,0])unless defined $opt{'print'};
			if ( ! ref $opt{'print'}){
				if ($opt{'print'} == -1){
					$opt{'print'} = pdl(long,[-1,0]);
				}
				elsif ($opt{'print'} == 0){
					$opt{'print'} = pdl(long,[$opt{'print'},0]);
				}
				else{
					$opt{'print'} = pdl(long,[$opt{'print'},0]);
				}
			}
			$ret{iter} = defined $opt{maxit} ? pdl ($opt{maxit}) : pdl(long , 50);
			$ret{info} = pdl(long,0);
			$opt{'m'} = pdl(long , 10) unless defined $opt{'m'};
			$iv = zeroes(long,44);
			$v = zeroes(29);
			lbfgsb($ret{fx}, $ret{gx}, $x, $opt{'m'}, $opt{bound}, $opt{tbound}, $ret{iter}, $opt{factr}, $opt{gtol}, $opt{eta},
			        $opt{'print'}, $ret{info},$iv, $v,$opt{fg_func});
			$ret{fcnt} = $iv(33);
		}
		elsif (substr($function,0,4) eq 'lmqn'){
			$ret{gx} = $x->zeroes;
	                #BUG => param maxfc && cg
			$opt{accrcy} = pdl(1e-16) unless defined $opt{accrcy};
			$opt{eps} = pdl(1e-10) unless defined $opt{eps};
			$opt{stepmx} = pdl(1) unless defined $opt{stepmx};
			$opt{eta} = pdl(0.25) unless defined $opt{eta};
			$ret{info} = pdl(long,0);
			$opt{'print'} = pdl(long,0)unless defined $opt{'print'};
			if ( (! ref $opt{'print'}) && defined($opt{'print'})){
				if ($opt{'print'} == -1){
					$opt{'print'} = pdl(long,0);
				}
				elsif ($opt{'print'} == 0){
					$opt{'print'} = pdl(long,1);
				}
				else{
					$opt{'print'} = pdl($opt{'print'});
				}
			}
			$ret{fcnt} = defined $opt{maxfc} ? pdl ($opt{maxfc}) : pdl(long , 200);
			$ret{iter} = defined $opt{maxit} ? pdl ($opt{maxit}) : pdl(long , 100);
			$opt{cgmaxit} = pdl(long, 50) unless defined $opt{cgmaxit};
			$opt{fg_func}($ret{fx}, $ret{gx}, $x);
			$opt{fg_func}($ret{fx}, $ret{gx}, $x);
			defined $opt{bound} ? 
			lmqnbc($ret{fx}, $ret{gx}, $x, $opt{bound}, $ret{iter}, $ret{fcnt}, $opt{cgmaxit}, $opt{eps}, $opt{accrcy}, $opt{eta}, $opt{stepmx}, $opt{'print'}, $ret{info}, $opt{fg_func}):
			lmqn($ret{fx}, $ret{gx}, $x, $ret{iter}, $ret{fcnt}, $opt{cgmaxit}, $opt{eps}, $opt{accrcy}, $opt{eta}, $opt{stepmx}, $opt{'print'}, $ret{info}, $opt{fg_func});
			if ($opt{'print'}){
				if($ret{info} == 0){
					print "Convergence in lmqn optimization\n";
				}
				elsif($ret{info} == 1){
					print "Too many iterations in lmqn optimization\n";
				}
				elsif($ret{info} == 2){
					print "Too many function evaluations in lmqn optimization\n";
				}
				elsif($ret{info} == 3){
					print "Line search failed to find lowest point in lmqn optimization\n";
				}
				else{
					print "Error $ret{info} in lmqn optimization\n";
				}
			}
		}
		elsif ($function eq 'cgfam'){
			$ret{gx} = $x->zeroes;
	                #BUG => param maxit			
			$opt{cgmethod} = pdl(long, 1) unless defined $opt{cgmethod};
			$opt{eps} = pdl(1e-16) unless defined $opt{eps};
			$opt{eta} = pdl(0.9) unless defined $opt{eta};
			$opt{gtol} = pdl(1e-10) unless defined $opt{gtol};
			$opt{'print'} = pdl(long,[-1,0])unless defined $opt{'print'};
			if ( ! ref $opt{'print'}){
				if ($opt{'print'} == -1){
					$opt{'print'} = pdl(long,[-1,0]);
				}
				elsif ($opt{'print'} == 0){
					$opt{'print'} = pdl(long,[$opt{'print'},0]);
				}
				else{
					$opt{'print'} = pdl(long,[$opt{'print'},0]);
				}
			}
			$ret{iter} = defined $opt{maxit} ? pdl ($opt{maxit}) : pdl(long , 200);
			$ret{info} = pdl(long,0);
			$opt{fg_func}($ret{fx}, $ret{gx}, $x);
			cgfam($ret{fx}, $ret{gx}, $x, $ret{iter}, $opt{gtol}, $opt{eps}, $opt{eta},$opt{'print'},$ret{info},$opt{cgmethod}, $opt{fg_func});
		}

	}
	elsif ($function eq 'tensoropt'){
		barf "optimize: no evaluation function\n" unless defined $opt{f_func};

		$opt{f_func}($ret{fx}, $x);
		my $hx = zeroes($x->dim(0),$x->dim(0));
		$ret{gx} = $x->zeroes;

		if (defined $opt{g_func}){
			$opt{gtype} = 2 unless defined $opt{gtype};
			$opt{g_func}($ret{gx}, $x);
		}
		else{
			$opt{g_func} = $opt{f_func};
			$opt{gtype} = 0;
		}
		if (defined $opt{h_func}){
			$opt{htype} = 2 unless defined $opt{htype};
			$opt{h_func}($hx, $x);
		}
		else{
			$opt{h_func} = $opt{f_func};
			$opt{htype} = 0;
		}

		if ( (! ref $opt{'print'}) && defined($opt{'print'})){
			if ($opt{'print'} == -1){
				$opt{'print'} = pdl(long,0);
			}
			elsif ($opt{'print'}){
				$opt{'print'} = pdl(long,2);
			}
			else {
				$opt{'print'} = pdl(long,1);
			}
		}

		$ret{iter} = defined $opt{maxit} ? pdl($opt{maxit}) : pdl(long , 100);
		$opt{'method'} = pdl(long , 1) unless defined $opt{'method'};
		$opt{gtol} =  pdl(1e-10) unless defined $opt{gtol};
		$opt{xtol} =  pdl(1e-16) unless defined $opt{xtol};
		$opt{stempx} =  pdl(1) unless defined $opt{stepmx};
		$opt{ipr} =  pdl(long,6) unless defined $opt{ipr};
		$opt{digits} =  pdl(long,16) unless defined $opt{digits};
		$opt{fscale} =  pdl(1) unless defined $opt{fscale};
		$opt{typx} =  ones($x->dim(0)) unless defined $opt{typx};

		tensoropt($ret{fx}, $ret{gx}, $hx, $x, 
			$opt{'method'},$ret{iter},$opt{digits},$opt{gtype},$opt{htype},$opt{fscale},
			$opt{typx},$opt{stempx},$opt{xtol},$opt{gtol},$opt{'print'},$opt{ipr},
			$opt{f_func}, $opt{g_func}, $opt{h_func});

	}
	elsif ($function eq ('gencan' )){
		barf "optimize: no evaluation function\n" unless defined $opt{f_func};
		$ret{gx} = $x->zeroes;

		if( ! defined $opt{g_func}){
			$opt{gtype} = pdl(long, 1);
			$opt{g_func} = sub {};
		}
		else {$opt{gtype} = pdl(long, 0);}

		if( ! defined $opt{h_func}){		
			$opt{htvtype} = pdl(long, 1);
			$opt{h_func} = sub {};
		}
		else{
			$opt{htvtype} = pdl(long, 0);
		}

		$opt{delta} = pdl(-1) unless defined $opt{delta};
		$opt{eta} = pdl(0.9) unless defined $opt{eta};
		$opt{delmin} = pdl(0.1) unless defined $opt{delmin};
		$opt{ftol} = pdl(0) unless defined $opt{ftol};
		$opt{fmaxit} = pdl(long, 5) unless defined $opt{fmaxit};
		$opt{gmaxit} = pdl(long, 10) unless defined $opt{gmaxit};
		$opt{interpmaxit} = pdl(long, 5) unless defined $opt{interpmaxit};
		$opt{cgstop} = pdl(long, 1) unless defined $opt{cgstop};
		$opt{cgmaxit} = pdl(long, -1) unless defined $opt{cgmaxit};
		$opt{qmpmaxit} = pdl(long, 5) unless defined $opt{qmpmaxit};
		$opt{cggtol} = pdl(1e-5) unless defined $opt{cggtol};
		$opt{cgintol} = pdl(0.1) unless defined $opt{cgintol};
		$opt{cgfitol} = pdl(1e-5) unless defined $opt{cgfitol};
		$opt{qmptol} = pdl(1e-5) unless defined $opt{qmptol};

		$opt{trtype} = pdl(long, 0) unless defined $opt{trtype};
		$opt{nearlyq} = pdl(long,0) unless defined $opt{nealryq};
		$opt{fmin} = pdl(-1e+308) unless defined $opt{fmin};
		$opt{trtype} = pdl(long,0) unless defined $opt{trtype};
		$opt{ncomp} = pdl(long,5) unless defined $opt{ncomp};
		$opt{'print'} = pdl(long,[-1,0])unless defined $opt{'print'};
		if ( ! ref $opt{'print'}){
			if ($opt{'print'} == -1){
				$opt{'print'} = pdl(long,[-1,0]);
			}
			elsif ($opt{'print'} == 0){
				$opt{'print'} = pdl(long,[$opt{'print'},0]);
			}
			else{
				$opt{'print'} = pdl(long,[$opt{'print'},0]);
			}
		}
		$opt{maxfc} = pdl(long , 1000) unless defined $opt{maxfc};
		$opt{maxit} = pdl(long , 200) unless defined $opt{maxit};

		$opt{lammax} = pdl(1e+40) unless defined $opt{lammax};
		$opt{lammin} = pdl(1e-40) unless defined $opt{lammin};
		$opt{theta} = pdl(1e-6) unless defined $opt{theta};
		$opt{gamma} = pdl(0.0001) unless defined $opt{gamma};
		$opt{beta} = pdl(0.5) unless defined $opt{beta};
		$opt{sigma1} = pdl(0.1) unless defined $opt{sigma1};
		$opt{sigma2} = pdl(0.9) unless defined $opt{sigma2};
		$opt{nint} = pdl(2) unless defined $opt{nint};
		$opt{'next'} = pdl(2) unless defined $opt{'next'};

		$opt{sterel} = pdl(1e-10) unless defined $opt{sterel};
		$opt{steabs} = pdl(1e-99) unless defined $opt{steabs};
		$opt{epsrel} = pdl(1e-30) unless defined $opt{epsrel};
		$opt{epsabs} = pdl(1e-99) unless defined $opt{epsabs};
		$opt{infty} = pdl(1e+308) unless defined $opt{infty};

		if (defined $opt{gtol}){
			$opt{gtol1} = $opt{gtol} unless defined $opt{gtol1};
			$opt{gtol2} = $opt{gtol} unless defined $opt{gtol2};
		}
		else{
			$opt{gtol1} = pdl(1-10) unless defined $opt{gtol1};
			$opt{gtol2} = pdl(1e-10) unless defined $opt{gtol2};
		}

		$ret{info} = pdl(long,0);
		$ret{gnorm1} = null;$ret{gnorm2} = null;
		$ret{iter} = null; $ret{fcnt}= null;$ret{spgfcnt}=null;
		$ret{gcnt} = null; $ret{cgcnt} = null; $ret{spgiter} = null;
		$ret{tniter} = null; $ret{tnfcnt} = null; $ret{tnstpcnt} = null; 
		$ret{tnintcnt}= null; $ret{tnexgcnt} = null; $ret{tnexbcnt} = null;
		$ret{tnintfe}= null; $ret{tnexgfe}= null; $ret{tnexbfe}=null;

		if (! defined $opt{bound}){
			$opt{bound} = zeroes($x->type, $x->dim(0),2);
			$opt{bound}->(,0).= pdl(-1e308);
			$opt{bound}->(,1).= pdl(1e308);
		}
			

		gencan($ret{fx}, $ret{gx}, $x, $opt{bound}, $opt{fmin}, $opt{maxit}, $opt{maxfc},
		$opt{nearlyq}, $opt{gtype}, $opt{htvtype}, $opt{trtype}, $opt{fmaxit}, $opt{gmaxit}, $opt{interpmaxit}, $opt{cgstop}, $opt{cgmaxit}, $opt{qmpmaxit},
		$opt{ftol}, $opt{gtol2}, $opt{gtol1}, $opt{cggtol}, $opt{cgintol}, $opt{cgfitol}, $opt{qmptol}, 
		$opt{delta}, $opt{eta}, $opt{delmin},
		$opt{lammax}, $opt{lammin}, $opt{theta}, $opt{gamma}, $opt{beta}, $opt{sigma1},$opt{sigma2},
		$opt{nint}, $opt{'next'}, $opt{sterel}, $opt{steabs}, $opt{epsrel}, $opt{epsabs}, $opt{infty},
		$ret{gnorm2}, $ret{gnorm1}, $ret{iter}, $ret{fcnt}, 
		$ret{gcnt}, $ret{cgcnt}, $ret{spgiter}, $ret{spgfcnt},
		$ret{tniter}, $ret{tnfcnt}, $ret{tnstpcnt}, $ret{tnintcnt}, $ret{tnexgcnt}, $ret{tnexbcnt},
		$ret{tnintfe}, $ret{tnexgfe}, $ret{tnexbfe},
		$opt{'print'},$opt{ncomp}, $ret{info}, $opt{f_func}, $opt{g_func}, $opt{h_func});
	
	}
	elsif ($function eq 'spg'){
		barf "optimize: no gradient evaluation function\n" unless defined $opt{g_func};
		barf "optimize: no evaluation function\n" unless defined $opt{f_func};

		# Bounded example
		$ret{info} = pdl(long,0);
		if ( (! ref $opt{'print'}) && defined($opt{'print'})){
			if ($opt{'print'} == -1){
				$opt{'print'} = pdl(long,0);
			}
			else {
				$opt{'print'} = pdl(long,1);
			}
		}
		$ret{fcnt} = pdl(long,0);
		$ret{gcnt} = pdl(long,0);
		$ret{iter} = defined $opt{maxit} ? pdl ($opt{maxit}) : pdl(long , 500);
		$opt{maxfc} = pdl(long , 1000) unless defined $opt{maxfc};
		$opt{'m'} = pdl(long , 100) unless defined $opt{'m'};

		$ret{gnorm1} = pdl(0);
		$ret{gnorm2} = pdl(0);
		if (defined $opt{gtol}){
			$opt{gtol1} = $opt{gtol} unless defined $opt{gtol1};
			$opt{gtol2} = $opt{gtol} unless defined $opt{gtol2};
		}
		else{
			$opt{gtol1} = pdl(0) unless defined $opt{gtol1};
			$opt{gtol2} = pdl(1e-5) unless defined $opt{gtol2};
		}

		$opt{pg_func} = sub{ return 0;}  unless defined $opt{pg_func};

		spg($ret{fx}, $x, $opt{'m'}, $ret{iter}, $opt{maxfc}, $opt{gtol1}, $opt{gtol2}, $opt{'print'},
				$ret{fcnt}, $ret{gcnt}, $ret{gnorm1}, $ret{gnorm2}, $ret{info}, $opt{f_func}, $opt{g_func}, $opt{pg_func});
		if ($opt{'print'}){
			if($ret{info} == 0){
				print "Convergence with projected gradient infinite-norm in spg optimization\n";;
			}
			elsif($ret{info} == 1){
				print "Convergence with projected gradient 2-norm in spg optimization\n";
			}
			elsif($ret{info} == 2){
				print "Too many iterations in spg optimization\n";
			}
			elsif($ret{info} == 4){
				print "Error in pg_func subroutine in spg optimization\n";
			}
			elsif($ret{info} == 5){
				print "Error in f_func subroutine in spg optimization\n";
			}
			elsif($ret{info} == 6){
				print "Error in g_func subroutine in spg optimization\n";
			}
		}
	}
	elsif ($function eq 'smnsx'){
		barf "optimize: no evaluation function\n" unless defined $opt{f_func};
		$ret{fx} = pdl(0);
		$ret{step} = defined $opt{step} ? pdl ($opt{step}) : pdl(0.5);
		$ret{stdev} = defined $opt{tol} ? pdl ($opt{tol}) : pdl(1e-16);
		smnsx($x, $ret{step}, $ret{stdev}, $ret{fx}, $opt{f_func});
	}
	elsif ($function eq 'mnsx'){
		barf "optimize: no evaluation function\n" unless defined $opt{f_func};
		barf "optimize: no vertices\n" unless defined $opt{vertices};
		$ret{fx} = pdl(0);
		$ret{vertices} = pdl $opt{vertices};
		$ret{stdev} = defined $opt{tol} ? pdl ($opt{tol}) : pdl(1e-16);
		$opt{maxit} = pdl(long , 1000) unless defined $opt{maxit};
		mnsx($x, $ret{vertices}, $opt{maxit}, $ret{stdev}, $ret{fx}, $opt{f_func});
	}
	elsif ($function eq 'rmn'){
		barf "optimize: no evaluation function\n" unless defined $opt{f_func};
		my ($dim,$iv, $v);
		$dim = $x->dim(0);
		if (defined $opt{bound}){
			if (defined $opt{h_func}){
				barf "optimize: no gradient evaluation function\n" unless defined $opt{g_func};
				$ret{gx} = $x->zeroes;
				$ret{hx} = zeroes($x->type, $dim *($dim+1)/2 );
				$v = zeroes(78 + $dim * ($dim+27)/2 );
				$iv = zeroes(long, 59 + 3*$dim);
				ivset(2,$iv,$v);
				$iv(16) .= $opt{maxfc} if defined $opt{maxfc};
				$iv(17) .= $opt{maxit} if defined $opt{maxit};
				if (defined $opt{'print'}){
					if ($opt{'print'} == -1){
						$iv(20).= 0;					
					}
					elsif($opt{'print'} == 0){
						$iv(18).= 0;
					}
					else{
						$iv(18).= $opt{'print'};
					}
				}
				else{
					$iv(20).= 0;
				}
				$v(34) .= $opt{stepmx} if defined $opt{stepmx};
				$v(31) .= $opt{rfctol} if defined $opt{rfctol};
				$v(32) .= $opt{xctol} if defined $opt{xctol};
				$opt{scale} = ones($x->type, $dim) unless defined $opt{scale};
				rmnhb($ret{fx}, $ret{gx}, $ret{hx}, $x, $opt{bound}->xchg(0,1), $opt{scale}, $iv, $v, $opt{f_func}, $opt{g_func}, $opt{h_func});
			}
			elsif (defined $opt{g_func}){
				$ret{gx} = $x->zeroes;
				$v = zeroes(71 + $dim *( $dim + 19 )/2);
				$iv = zeroes(long,59+$dim);
				ivset(2,$iv,$v);
				$iv(16) .= $opt{maxfc} if defined $opt{maxfc};
				$iv(17) .= $opt{maxit} if defined $opt{maxit};
				if (defined $opt{'print'}){
					if ($opt{'print'} == -1){
						$iv(20).= 0;					
					}
					elsif($opt{'print'} == 0){
						$iv(18).= 0;
					}
					else{
						$iv(18).= $opt{'print'};
					}
				}
				else{
					$iv(20).= 0;
				}
				$v(34) .= $opt{stepmx} if defined $opt{stepmx};
				$v(31) .= $opt{rfctol} if defined $opt{rfctol};
				$v(32) .= $opt{xctol} if defined $opt{xctol};
				$opt{scale} = ones($x->type, $dim) unless defined $opt{scale};
				rmngb($ret{fx}, $ret{gx}, $x, $opt{bound}->xchg(0,1), $opt{scale}, $iv, $v, $opt{f_func}, $opt{g_func});
			}
			else{
				$v = zeroes(77 + $dim *($dim+23));
				$iv = zeroes(long,59+$dim);
				ivset(2,$iv,$v);
				$iv(16) .= $opt{maxfc} if defined $opt{maxfc};
				$iv(17) .= $opt{maxit} if defined $opt{maxit};
				if (defined $opt{'print'}){
					if ($opt{'print'} == -1){
						$iv(20).= 0;					
					}
					elsif($opt{'print'} == 0){
						$iv(18).= 0;
					}
					else{
						$iv(18).= $opt{'print'};
					}
				}
				else{
					$iv(20).= 0;
				}
				$v(41).= $opt{eta} if defined $opt{eta};
				$v(34) .= $opt{stepmx} if defined $opt{stepmx};
				$v(31) .= $opt{rfctol} if defined $opt{rfctol};
				$v(32) .= $opt{xctol} if defined $opt{xctol};
				$opt{scale} = ones($x->type, $dim) unless defined $opt{scale};
				rmnfb($ret{fx}, $ret{gx}, $x, $opt{bound}->xchg(0,1), $opt{scale}, $iv, $v, $opt{f_func});
			}
		}
		else{
			if (defined $opt{h_func}){
				barf "optimize: no gradient evaluation function\n" unless defined $opt{g_func};
				$ret{gx} = $x->zeroes;
				$ret{hx} = zeroes($x->type, $dim *($dim+1)/2 );
				$v = zeroes(78 + $dim * ($dim+21)/2 );
				$iv = zeroes(long, 59);
				ivset(2,$iv,$v);
				$iv(16) .= $opt{maxfc} if defined $opt{maxfc};
				$iv(17) .= $opt{maxit} if defined $opt{maxit};
				if (defined $opt{'print'}){
					if ($opt{'print'} == -1){
						$iv(20).= 0;					
					}
					elsif($opt{'print'} == 0){
						$iv(18).= 0;
					}
					else{
						$iv(18).= $opt{'print'};
					}
				}
				else{
					$iv(20).= 0;
				}
				$v(34) .= $opt{stepmx} if defined $opt{stepmx};
				$v(31) .= $opt{rfctol} if defined $opt{rfctol};
				$v(32) .= $opt{xctol} if defined $opt{xctol};
				$opt{scale} = ones($x->type, $dim) unless defined $opt{scale};
				rmnh($ret{fx}, $ret{gx}, $ret{hx}, $x, $opt{scale}, $iv, $v, $opt{f_func}, $opt{g_func}, $opt{h_func});
			}
			elsif (defined $opt{g_func}){
				$ret{gx} = $x->zeroes;
				$v = zeroes(71 + $dim *( $dim + 13 )/2);
				$iv = zeroes(long,59);
				ivset(2,$iv,$v);
				$iv(16) .= $opt{maxfc} if defined $opt{maxfc};
				$iv(17) .= $opt{maxit} if defined $opt{maxit};
				if (defined $opt{'print'}){
					if ($opt{'print'} == -1){
						$iv(20).= 0;					
					}
					elsif($opt{'print'} == 0){
						$iv(18).= 0;
					}
					else{
						$iv(18).= $opt{'print'};
					}
				}
				else{
					$iv(20).= 0;
				}
				$v(34) .= $opt{stepmx} if defined $opt{stepmx};
				$v(31) .= $opt{rfctol} if defined $opt{rfctol};
				$v(32) .= $opt{xctol} if defined $opt{xctol};
				$opt{scale} = ones($x->type, $dim) unless defined $opt{scale};
				rmng($ret{fx}, $ret{gx}, $x, $opt{scale}, $iv, $v, $opt{f_func}, $opt{g_func});
			}
			else{
				$v = zeroes(77 + $dim *($dim+17)/2);
				$iv = zeroes(long,59);
				ivset(2,$iv,$v);
				$iv(16) .= $opt{maxfc} if defined $opt{maxfc};
				$iv(17) .= $opt{maxit} if defined $opt{maxit};
				if (defined $opt{'print'}){
					if ($opt{'print'} == -1){
						$iv(20).= 0;					
					}
					elsif($opt{'print'} == 0){
						$iv(18).= 0;
					}
					else{
						$iv(18).= $opt{'print'};
					}
				}
				else{
					$iv(20).= 0;
				}
				$v(41).= $opt{eta} if defined $opt{eta};
				$v(34) .= $opt{stepmx} if defined $opt{stepmx};
				$v(31) .= $opt{rfctol} if defined $opt{rfctol};
				$v(32) .= $opt{xctol} if defined $opt{xctol};
				$opt{scale} = ones($x->type, $dim) unless defined $opt{scale};
				rmnf($ret{fx}, $ret{gx}, $x, $opt{scale}, $iv, $v, $opt{f_func});
			}
		}
		$ret{fcnt} = $iv(5);
		$ret{gcnt} = $iv(29);
		$ret{info} = $iv(0);
		$ret{iter} = $iv(30);
		$ret{fx} = $v(9);
		$ret{gnorm2} = $v(0);
	}
	else{
		barf "$function is not supported\n";
	}
	wantarray ? return $x, %ret : return $x;

}

sub rosen_grad{
	my $a = shift;
        my( $am, $am_m1, $am_p1, $grad);
	$am = $a(1:-2);
        $am_m1 = $a(:-3);
        $am_p1 = $a(2:);
	$grad = $a->zeroes;
	$grad(1:-2) .= 200 *( $am - $am_m1->power(2,0)) - 400*($am_p1 - $am->power(2,0))*$am - 2*(1-$am);
	$grad(0) .= -400 * $a(0) * ($a(1) - $a(0)->power(2,0)) - 2*(1-$a(0));
    	$grad(-1) .= 200 * ( $a(-1) - $a(-2)->power(2,0) );
    	return $grad;
}

sub rosen_hess{
	my ($a, $squared) = @_;
	my ($hess,$diag);
	#$diag = $a(:-2)->mult(-400,0)->diag(1);
	#$hess = $diag + $diag->xchg(0,1);
	$hess = $a(:-2)->mult(-400,0)->diag(1);
	$diag = $a->zeroes;
	$diag(0) .= 1200 * $a(0) - 400 * $a(1) + 2;
        $diag(-1) .= 200;
        $diag(1:-2) .= 202 + 1200 * $a(1:-2)->power(2,0) - 400 * $a(2:);
        $hess->diagonal(0,1) += $diag;
	$squared  ? return $hess->tritosym : return  $hess;
        
}

=head1 COPYRIGHT

Copyright (C) Grégory Vanuxem 2005-2018.
All rights reserved. This program is free software; you can
redistribute it and/or modify it under the same terms as Perl itself.

=cut





# Exit with OK status

1;

		   