
#
# GENERATED WITH PDL::PP! Don't modify!
#
package PDL::LinearAlgebra::Trans;

@EXPORT_OK  = qw(   mexp mexpts mlog msqrt mpow 
			mcos msin mtan	msec mcsc mcot
			mcosh  msinh  mtanh  msech  mcsch  mcoth
			macos masin matan masec macsc macot 
			macosh masinh matanh masech macsch macoth
			sec asec sech asech 
			cot acot acoth coth mfun
			csc acsc csch acsch toreal pi PDL::PP geexp PDL::PP cgeexp PDL::PP ctrsqrt PDL::PP ctrfun );
%EXPORT_TAGS = (Func=>[@EXPORT_OK]);

use PDL::Core;
use PDL::Exporter;
use DynaLoader;



   $PDL::LinearAlgebra::Trans::VERSION = '0.12';
   @ISA    = ( 'PDL::Exporter','DynaLoader' );
   push @PDL::Core::PP, __PACKAGE__;
   bootstrap PDL::LinearAlgebra::Trans $VERSION;




use PDL::Func;
use PDL::Core;
use PDL::Slices;
use PDL::Ops qw//;
use PDL::Math qw/floor/;
use PDL::Complex;
use PDL::NiceSlice;
use PDL::LinearAlgebra;
use PDL::LinearAlgebra::Real qw //;
use PDL::LinearAlgebra::Complex qw //;
use strict;

=encoding Latin-1

=head1 NAME

PDL::LinearAlgebra::Trans - Linear Algebra based transcendental functions for PDL

=head1 SYNOPSIS

 use PDL::LinearAlgebra::Trans;

 $a = random (100,100);
 $sqrt = msqrt($a);

=head1 DESCRIPTION

This module provides some transcendental functions for matrices.
Moreover it provides sec, asec, sech, asech, cot, acot, acoth, coth, csc,
acsc, csch, acsch. Beware, importing this module will overwrite the hidden
PDL routine sec. If you need to call it specify its origin module : PDL::Basic::sec(args)








=head1 FUNCTIONS



=cut






=head2 geexp

=for sig

  Signature: ([io,phys]A(n,n);int deg();scale();[io]trace();int [o]ns();int [o]info())

=for ref

Computes exp(t*A), the matrix exponential of a general matrix,
using the irreducible rational Pade approximation to the 
exponential function exp(x) = r(x) = (+/-)( I + 2*(q(x)/p(x)) ), 
combined with scaling-and-squaring and optionaly normalization of the trace.
The algorithm is described in Roger B. Sidje (rbs.uq.edu.au)
"EXPOKIT: Software Package for Computing Matrix Exponentials".
ACM - Transactions On Mathematical Software, 24(1):130-156, 1998


     A:		On input argument matrix. On output exp(t*A).
     		Use Fortran storage type.

     deg:	the degre of the diagonal Pade to be used. 
                a value of 6 is generally satisfactory. 

     scale:	time-scale (can be < 0). 

     trace:	on input, boolean value indicating whether or not perform
     		a trace normalization. On output value used.

     ns:	on output number of scaling-squaring used. 

     info:	exit flag.
                      0 - no problem 
                     > 0 - Singularity in LU factorization when solving 
		     Pade approximation

=for example

  = random(5,5);
  = pdl(1);
 ->xchg(0,1)->geexp(6,1,, ( = null), ( = null));



=for bad

geexp does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*geexp = \&PDL::geexp;





=head2 cgeexp

=for sig

  Signature: ([io,phys]A(2,n,n);int deg();scale();int trace();int [o]ns();int [o]info())



=for ref

Complex version of geexp. The value used for trace normalization is not returned.
The algorithm is described in Roger B. Sidje (rbs@maths.uq.edu.au)
"EXPOKIT: Software Package for Computing Matrix Exponentials".
ACM - Transactions On Mathematical Software, 24(1):130-156, 1998




=for bad

cgeexp does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*cgeexp = \&PDL::cgeexp;





=head2 ctrsqrt

=for sig

  Signature: ([io,phys]A(2,n,n);int uplo();[phys,o] B(2,n,n);int [o]info())



=for ref

Root square of complex triangular matrix. Uses a recurrence of Björck and Hammarling.
(See Nicholas J. Higham. A new sqrtm for MATLAB. Numerical Analysis
Report No. 336, Manchester Centre for Computational Mathematics,
Manchester, England, January 1999. It's available at http://www.ma.man.ac.uk/~higham/pap-mf.html)
If uplo is true, A is lower triangular.



=for bad

ctrsqrt does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrsqrt = \&PDL::ctrsqrt;





=head2 ctrfun

=for sig

  Signature: ([io,phys]A(2,n,n);int uplo();[phys,o] B(2,n,n);int [o]info(); SV* func)



=for ref

Apply an arbitrary function to a complex triangular matrix. Uses a recurrence of Parlett.
If uplo is true, A is lower triangular.




=for bad

ctrfun does not process bad values.
It will set the bad-value flag of all output piddles if the flag is set for any of the input piddles.


=cut






*ctrfun = \&PDL::ctrfun;



my $pi;
BEGIN { $pi = pdl(3.1415926535897932384626433832795029) }
sub pi () { $pi->copy };

*sec = \&PDL::sec;
sub PDL::sec{1/cos($_[0])}

*csc = \&PDL::csc;
sub PDL::csc($) {1/sin($_[0])}

*cot = \&PDL::cot;
sub PDL::cot($) {1/(sin($_[0])/cos($_[0]))}

*sech = \&PDL::sech;
sub PDL::sech($){1/pdl($_[0])->cosh}

*csch = \&PDL::csch;
sub PDL::csch($) {1/pdl($_[0])->sinh}

*coth = \&PDL::coth;
sub PDL::coth($) {1/pdl($_[0])->tanh}

*asec = \&PDL::asec;
sub PDL::asec($) {my $tmp = 1/pdl($_[0]) ; $tmp->acos}

*acsc = \&PDL::acsc;
sub PDL::acsc($) {my $tmp = 1/pdl($_[0]) ; $tmp->asin}

*acot = \&PDL::acot;
sub PDL::acot($) {my $tmp = 1/pdl($_[0]) ; $tmp->atan}

*asech = \&PDL::asech;
sub PDL::asech($) {my $tmp = 1/pdl($_[0]) ; $tmp->acosh}

*acsch = \&PDL::acsch;
sub PDL::acsch($) {my $tmp = 1/pdl($_[0]) ; $tmp->asinh}

*acoth = \&PDL::acoth;
sub PDL::acoth($) {my $tmp = 1/pdl($_[0]) ; $tmp->atanh}

my $_tol = 9.99999999999999e-15;

sub toreal{
	return $_[0] if $_[0]->isempty;
	$_tol = $_[1] if defined $_[1];
	my ($min, $max, $tmp);
	($min, $max) = $_[0]->slice('(1)')->minmax;
	return re($_[0])->sever unless (abs($min) > $_tol || abs($max) > $_tol);
	$_[0];
}

=head2 mlog

=for ref

Return matrix logarithm of a square matrix.

=for usage

 PDL = mlog(PDL(A))

=for example

 my $a = random(10,10);
 my $log = mlog($a);

=cut

*mlog = \&PDL::mlog;
sub PDL::mlog {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("mlog requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	mfun($m, sub{$_[0].=log $_[0]} , 0, $tol);
}

=head2 msqrt

=for ref

Return matrix square root (principal) of a square matrix.

=for usage

 PDL = msqrt(PDL(A))

=for example

 my $a = random(10,10);
 my $sqrt = msqrt($a);

=cut

*msqrt = \&PDL::msqrt;

sub PDL::msqrt {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("msqrt requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	$m = $m->r2C unless @dims == 3;
	my ($t, undef, $z, undef, $info) = $m->mschur(1);
	if ($info){
		warn "msqrt: Can't compute Schur form\n";
		return;		
	}
	($t, $info) = $t->ctrsqrt(0);
	if($info){
		warn "msqrt: can't compute square root\n";
		return;
	}
	$m = $z x $t x $z->t(1);
	return (@dims ==3) ? $m : toreal($m, $tol);
}

=head2 mexp

=for ref

Return matrix exponential of a square matrix.

=for usage

 PDL = mexp(PDL(A))

=for example

 my $a = random(10,10);
 my $exp = mexp($a);

=cut

*mexp = \&PDL::mexp;
sub PDL::mexp {
	my ($m, $order, $trace) = @_;
	my @dims = $m->dims;
	barf("mexp requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($info, $ns);
	$info  = PDL::null;
	$ns = PDL::null;
	$trace = 1 unless defined $trace;
	$order = 6 unless defined $order;
	$m = $m->copy;
	@dims == 3 ? $m->xchg(1,2)->cgeexp($order, 1, $trace, $ns, $info) :
			$m->xchg(0,1)->geexp($order, 1, $trace, $ns, $info);
	if ($info){
		warn "mexp: Error $info";
	}
	else{
		return $m;
	}
}

#*mexp2 = \&PDL::mexp2;
#sub PDL::mexp2 {
#	my ($m, $order) = @_;
#	my @dims = $m->dims;
#	barf("mexp requires a 2-D square matrix")
#		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

#	my ($norm, $X, $c, $D, $N, $fact, $cX, $trace);
#	if (defined $order){
#		$order++;
#	}
#	else{
#		$order = 8;
#	}
	

	# Trace normalization
#	$m = $m->copy;
#	$trace = $m->diag->sumover / $m->dim(1);

#	if (@dims == 3){
#		$trace = $trace->im->r2C if ($trace->re < 0);
#		$m->diagonal(1,2) .= $m->diagonal(1,2) - $trace;	
#	}
#	elsif ($trace > 0){
#		$m->diagonal(0,1) -= $trace;
#	}
	



	# Scale M
#	$norm = $m->mnorm(0);
#	$norm = $norm > 0 ?  PDL::floor(1 + ($norm->log / log(2))) : 0;
#	$norm = 0 unless $norm > 0;
#	$m = $m / 2**$norm if $norm > 0;

#	$X = $m;
#	$N = $m / 2;
#	$D = -$m / 2;
#	$c = 0.5;
#	if (@dims == 3){
#		$N->re->diagonal(0,1)++;
#		$D->re->diagonal(0,1)++;
#	}
#	else{
#		$N->diagonal(0,1)++;
#		$D->diagonal(0,1)++;
#	}
#
#	for ($fact = 2; $fact <= $order;$fact++){
#		# Padé coeff
#		$c = $c * ($order - $fact + 1 ) / ($fact * (2 * $order - $fact +1));
#
#		if (@dims == 3){
#			$X = PDL::cmmult($m, $X);
#			$cX = PDL::Complex::Cmul($X, PDL::Complex::r2C(PDL->pdl($c)));
#		}
#		else{
#			$X = PDL::mmult($m, $X);
#			$cX = PDL::mult($X, PDL->pdl($c),0);
#		}
#		$N = PDL::plus($N,$cX,0);
#		$D = ($fact % 2) ? PDL::minus($D,$cX,0) :
#			PDL::plus($D,$cX,0);
#	}	
#
#	$X = PDL::msolvex($D,$N, equilibrate=>1);
#
#	# Squaring
#	if($norm > 0){
#		for(1..$norm){
#			$X x= $X;
#		}
#	}
#	
#	# Reverse trace normalization	
#	$X = $trace->exp * $X if (@dims == 3 || $trace > 0);
#	$X;
#}


*mexpts = \&PDL::mexpts;
sub PDL::mexpts {
	my ($m, $order, $tol) = @_;
	my @dims = $m->dims;
	barf("mexp1 requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($em, $trm);
	$order = 20 unless defined $order;
	$em = (@dims == 3 ) ? diag(r2C ones($dims[1])) : diag(ones($dims[1]));
	$trm = $em->copy;
	for (1..($order - 1)){
		$trm =  $trm x ($m / $_);
	        $em += $trm;
	}
	return (@dims ==3) ? $em : toreal($em, $tol);
}

=head2 mpow

=for ref

Return matrix power of a square matrix.

=for usage

 PDL = mpow(PDL(A), SCALAR(exponent))

=for example

 my $a = random(10,10);
 my $powered = mpow($a,2.5);

=cut

#TODO: improve it (really crappy)

*mpow = \&PDL::mpow;
sub PDL::mpow {
	my ($m, $power, $tol, $eigen) = @_;
	my @dims = $m->dims;
	barf("mpow requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my $ret;
	if (UNIVERSAL::isa($power,'PDL') and $power->dims > 1){
		my ($e, $v) = $m->meigen(0,1);
		$ret = $v * $e->Cpow($power) x $v->minv;
	}
	elsif( 1/$dims[-1] * 1000 > abs($power)  and !$eigen){
		$ret = $m;
		my $pow = floor($power);
		$pow++ if ($power < 0 and $power != $pow);
                
                # TODO: what a beautiful thing (is it a game ?)
		for(my $i = 1; $i < abs($pow); $i++){	$ret x= $m;}
		$ret = $ret->minv if $power < 0;
		if ($power = $power - $pow){
			if($power == 0.5){
				my $v = $m->msqrt;
				$ret = ($pow == 0) ? $v : $ret x $v;
			}
			else{
				my ($e, $v) = $m->meigen(0,1);
				$ret = ($pow == 0) ? ($v * $e**$power x $v->minv) : $ret->r2C x ($v * $e**$power x $v->minv);
			}			
		}
	}
	else{
		my ($e, $v) = $m->meigen(0,1);
		$ret = $v * $e**$power x $v->minv;
	}
	return (@dims ==3) ? $ret : toreal($ret, $tol);

}

=head2 mcos

=for ref

Return matrix cosine of a square matrix.

=for usage

 PDL = mcos(PDL(A))

=for example

 my $a = random(10,10);
 my $cos = mcos($a);

=cut

*mcos = \&PDL::mcos;
sub PDL::mcos {
	my $m = shift;
	my @dims = $m->dims;
	barf("mcos requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return (@dims == 3) ? (mexp(i*$m) + mexp(- i*$m)) / 2 : re(mexp(i*$m))->sever;
}

=head2 macos

=for ref

Return matrix inverse cosine of a square matrix.

=for usage

 PDL = macos(PDL(A))

=for example

 my $a = random(10,10);
 my $acos = macos($a);

=cut

*macos = \&PDL::macos;
sub PDL::macos {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("macos requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($id, $ret);
	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	$ret = i * mlog( ($m->r2C - i * msqrt( ($id - $m x $m), $tol)));
	return (@dims ==3) ? $ret : toreal($ret, $tol);
}

=head2 msin

=for ref

Return matrix sine of a square matrix.

=for usage

 PDL = msin(PDL(A))

=for example

 my $a = random(10,10);
 my $sin = msin($a);

=cut

*msin = \&PDL::msin;
sub PDL::msin {
	my $m = shift;
	my @dims = $m->dims;
	barf("msin requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return (@dims == 3) ? (mexp(i*$m) - mexp(- i*$m))/(2*i) : im(mexp(i*$m))->sever;

}

=head2 masin

=for ref

Return matrix inverse sine of a square matrix.

=for usage

 PDL = masin(PDL(A))

=for example

 my $a = random(10,10);
 my $asin = masin($a);

=cut

*masin = \&PDL::masin;
sub PDL::masin {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("masin requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($ret, $id);
	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	$ret = (- i) * mlog(((i*$m) + msqrt($id - $m x $m, $tol)));
	return (@dims ==3) ? $ret : toreal($ret, $tol);
}

=head2 mtan

=for ref

Return matrix tangent of a square matrix.

=for usage

 PDL = mtan(PDL(A))

=for example

 my $a = random(10,10);
 my $tan = mtan($a);

=cut

*mtan = \&PDL::mtan;
sub PDL::mtan {
	my ($m, $id) = @_;
	my @dims = $m->dims;
	barf("mtan requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return scalar msolvex(mcos($m), msin($m),equilibrate=>1) unless $id;

	
	if (@dims == 3){
		$id = PDL::zeroes $m;
		$id->slice('(0),:,:')->diagonal(0,1) .= 1;
		$m = mexp(-2*i*$m);
		return scalar msolvex( ($id + $m ),( (- i) * ($id - $m)),equilibrate=>1);
	}
	else{
		$m = mexp(i * $m);
		return scalar $m->re->msolvex($m->im,equilibrate=>1);
	}

}

=head2 matan

=for ref

Return matrix inverse tangent of a square matrix.

=for usage

 PDL = matan(PDL(A))

=for example

 my $a = random(10,10);
 my $atan = matan($a);

=cut

*matan = \&PDL::matan;
sub PDL::matan {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("matan requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($id, $ret);
	$id = PDL::zeroes($m)->r2C;
	$id->re->diagonal(0,1) .= 1;
	$ret = - i/2 * mlog( scalar PDL::msolvex( ($id - i*$m) ,($id + i*$m),equilibrate=>1 ));
	return (@dims ==3) ? $ret : toreal($ret, $tol);
}

=head2 mcot

=for ref

Return matrix cotangent of a square matrix.

=for usage

 PDL = mcot(PDL(A))

=for example

 my $a = random(10,10);
 my $cot = mcot($a);

=cut

*mcot = \&PDL::mcot;
sub PDL::mcot {
	my ($m, $id) = @_;
	my @dims = $m->dims;
	barf("mcot requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return scalar msolvex(msin($m),mcos($m),equilibrate=>1) unless $id;

	if (@dims == 3){
		$id = PDL::zeroes $m;
		$id->slice('(0),:,:')->diagonal(0,1) .= 1;
		$m = mexp(-2*i*$m);
		return  scalar msolvex( ($id - $m ),(  i * ($id + $m)),equilibrate=>1);
	}
	else{
		$m = mexp(i * $m);
		return scalar $m->im->msolvex($m->re,equilibrate=>1);
	}
}

=head2 macot

=for ref

Return matrix inverse cotangent of a square matrix.

=for usage

 PDL = macot(PDL(A))

=for example

 my $a = random(10,10);
 my $acot = macot($a);

=cut

*macot = \&PDL::macot;
sub PDL::macot {
	my ($m, $tol, $id) = @_;
	my @dims = $m->dims;
	barf("macot requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($inv, $info) = $m->minv;
	if ($info){
		warn "macot: singular matrix";
		return;
	}
	return matan($inv,$tol);
}

=head2 msec

=for ref

Return matrix secant of a square matrix.

=for usage

 PDL = msec(PDL(A))

=for example

 my $a = random(10,10);
 my $sec = msec($a);

=cut

*msec = \&PDL::msec;
sub PDL::msec {
	my $m = shift;
	my @dims = $m->dims;
	barf("msec requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return (@dims == 3) ? PDL::minv(mexp(i+$m) + mexp(- i*$m)) * 2 : scalar PDL::minv(re(mexp(i*$m)));
}

=head2 masec

=for ref

Return matrix inverse secant of a square matrix.

=for usage

 PDL = masec(PDL(A))

=for example

 my $a = random(10,10);
 my $asec = masec($a);

=cut

*masec = \&PDL::masec;
sub PDL::masec {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("masec requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($inv, $info) = $m->minv;
	if ($info){
		warn "masec: singular matrix";
		return;
	}
	return macos($inv,$tol);
}

=head2 mcsc

=for ref

Return matrix cosecant of a square matrix.

=for usage

 PDL = mcsc(PDL(A))

=for example

 my $a = random(10,10);
 my $csc = mcsc($a);

=cut

*mcsc = \&PDL::mcsc;
sub PDL::mcsc {
	my $m = shift;
	my @dims = $m->dims;
	barf("mcsc requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return (@dims == 3) ? PDL::minv(mexp(i*$m) - mexp(- i*$m)) * 2*i : scalar PDL::minv(im(mexp(i*$m)));

}

=head2 macsc

=for ref

Return matrix inverse cosecant of a square matrix.

=for usage

 PDL = macsc(PDL(A))

=for example

 my $a = random(10,10);
 my $acsc = macsc($a);

=cut

*macsc = \&PDL::macsc;
sub PDL::macsc {
	my ($m, $tol) = @_;
	my @dims = $m->dims;
	barf("macsc requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($inv, $info) = $m->minv;
	if ($info){
		warn "macsc: singular matrix";
		return;
	}
	return masin($inv,$tol);
}

=head2 mcosh

=for ref

Return matrix hyperbolic cosine of a square matrix.

=for usage

 PDL = mcosh(PDL(A))

=for example

 my $a = random(10,10);
 my $cos = mcosh($a);

=cut

*mcosh = \&PDL::mcosh;

sub PDL::mcosh {
	my $m  = shift;
	my @dims = $m->dims;
	barf("mcosh requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	( $m->mexp + mexp(-$m) )/2;
}

=head2 macosh

=for ref

Return matrix hyperbolic inverse cosine of a square matrix.

=for usage

 PDL = macosh(PDL(A))

=for example

 my $a = random(10,10);
 my $acos = macosh($a);

=cut

*macosh = \&PDL::macosh;

sub PDL::macosh {
	my ($m, $tol)  =  @_;
	my @dims = $m->dims;
	barf("macosh requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($id, $ret);
	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	$ret = msqrt($m x $m - $id);
	$m = $m->r2C if $ret->getndims > @dims;
	mlog($m + $ret, $tol);
}

=head2 msinh

=for ref

Return matrix hyperbolic sine of a square matrix.

=for usage

 PDL = msinh(PDL(A))

=for example

 my $a = random(10,10);
 my $sinh = msinh($a);

=cut

*msinh = \&PDL::msinh;

sub PDL::msinh {
	my $m  = shift;
	my @dims = $m->dims;
	barf("msinh requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	( $m->mexp - mexp(-$m) )/2;
}

=head2 masinh

=for ref

Return matrix hyperbolic inverse sine of a square matrix.

=for usage

 PDL = masinh(PDL(A))

=for example

 my $a = random(10,10);
 my $asinh = masinh($a);

=cut

*masinh = \&PDL::masinh;

sub PDL::masinh {
	my ($m, $tol)  = @_;
	my @dims = $m->dims;
	barf("masinh requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	my ($id, $ret);
	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	$ret = msqrt($m x $m + $id);
	$m = $m->r2C if $ret->getndims > @dims;	
	mlog(($m + $ret), $tol);

}

=head2 mtanh

=for ref

Return matrix hyperbolic tangent of a square matrix.

=for usage

 PDL = mtanh(PDL(A))

=for example

 my $a = random(10,10);
 my $tanh = mtanh($a);

=cut

*mtanh = \&PDL::mtanh;

sub PDL::mtanh {
	my ($m, $id)  = @_;
	my @dims = $m->dims;
	barf("mtanh requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	return scalar msolvex(mcosh($m), msinh($m),equilibrate=>1) unless $id;

	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	$m = mexp(-2*$m);
	return  scalar msolvex( ($id + $m ),($id - $m), equilibrate=>1);
}

=head2 matanh

=for ref

Return matrix hyperbolic inverse tangent of a square matrix.

=for usage

 PDL = matanh(PDL(A))

=for example

 my $a = random(10,10);
 my $atanh = matanh($a);

=cut

*matanh = \&PDL::matanh;

sub PDL::matanh {
	my ($m, $tol)  = @_;
	my @dims = $m->dims;
	barf("matanh requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($id, $ret);
	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	mlog( scalar msolvex( ($id - $m ),($id + $m),equilibrate=>1), $tol ) / 2;
}

=head2 mcoth

=for ref

Return matrix hyperbolic cotangent of a square matrix.

=for usage

 PDL = mcoth(PDL(A))

=for example

 my $a = random(10,10);
 my $coth = mcoth($a);

=cut

*mcoth = \&PDL::mcoth;

sub PDL::mcoth {
	my ($m, $id)  = @_;
	my @dims = $m->dims;
	barf("mcoth requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	
	scalar msolvex(msinh($m), mcosh($m),equilibrate=>1) unless $id;
	$id = PDL::zeroes $m;
	(@dims == 3) ? $id->slice('(0),:,:')->diagonal(0,1) .= 1 : $id->diagonal(0,1) .= 1;
	$m = mexp(-2*$m);
	return  scalar msolvex( ($id - $m ),($id + $m),equilibrate=>1);
}

=head2 macoth

=for ref

Return matrix hyperbolic inverse cotangent of a square matrix.

=for usage

 PDL = macoth(PDL(A))

=for example

 my $a = random(10,10);
 my $acoth = macoth($a);

=cut

*macoth = \&PDL::macoth;

sub PDL::macoth {
	my ($m, $tol)  = @_;
	my @dims = $m->dims;
	barf("macoth requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($inv, $info) = $m->minv;
	if ($info){
		warn "macoth: singular matrix";
		return;
	}
	return matanh($inv,$tol);
}

=head2 msech

=for ref

Return matrix hyperbolic secant of a square matrix.

=for usage

 PDL = msech(PDL(A))

=for example

 my $a = random(10,10);
 my $sech = msech($a);

=cut

*msech = \&PDL::msech;

sub PDL::msech {
	my $m  = shift;
	my @dims = $m->dims;
	barf("msech requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	PDL::minv( $m->mexp + mexp(-$m) ) * 2;
}

=head2 masech

=for ref

Return matrix hyperbolic inverse secant of a square matrix.

=for usage

 PDL = masech(PDL(A))

=for example

 my $a = random(10,10);
 my $asech = masech($a);

=cut

*masech = \&PDL::masech;

sub PDL::masech {
	my ($m, $tol)  = @_;
	my @dims = $m->dims;
	barf("masech requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($inv, $info) = $m->minv;
	if ($info){
		warn "masech: singular matrix";
		return;
	}
	return macosh($inv,$tol);
}

=head2 mcsch

=for ref

Return matrix hyperbolic cosecant of a square matrix.

=for usage

 PDL = mcsch(PDL(A))

=for example

 my $a = random(10,10);
 my $csch = mcsch($a);

=cut

*mcsch = \&PDL::mcsch;

sub PDL::mcsch {
	my $m  = shift;
	my @dims = $m->dims;
	barf("mcsch requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	PDL::minv( $m->mexp - mexp(-$m) ) * 2;
}

=head2 macsch

=for ref

Return matrix hyperbolic inverse cosecant of a square matrix.

=for usage

 PDL = macsch(PDL(A))

=for example

 my $a = random(10,10);
 my $acsch = macsch($a);

=cut

*macsch = \&PDL::macsch;

sub PDL::macsch {
	my ($m, $tol)  = @_;
	my @dims = $m->dims;
	barf("macsch requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

	my ($inv, $info) = $m->minv;
	if ($info){
		warn "macsch: singular matrix";
		return;
	}
	return masinh($inv,$tol);
}

=head2 mfun

=for ref

Return matrix function of second argument of a square matrix.
Function will be applied on a PDL::Complex object.

=for usage

 PDL = mfun(PDL(A),'cos')

=for example

 my $a = random(10,10);
 my $fun = mfun($a,'cos');
 sub sinbycos2{
 	$_[0]->set_inplace(0);
 	$_[0] .= $_[0]->Csin/$_[0]->Ccos**2;
 }
 # Try diagonalization
 $fun = mfun($a, \&sinbycos2,1);
 # Now try Schur/Parlett
 $fun = mfun($a, \&sinbycos2);
 # Now with function.
 scalar msolve($a->mcos->mpow(2), $a->msin);

=cut

*mfun = \&PDL::mfun;

sub PDL::mfun {
	my ($m, $method, $diag, $tol)  = @_;
	my @dims = $m->dims;
	barf("mfun requires a 2-D square matrix")
		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );
	
	if ($diag){
		my ($e, $v, $inv, $info);
		($e, $v) = $m->meigen(0,1);
	
		($inv, $info) = $v->minv;
		unless ($info){
			$method = 'PDL::Complex::'.$method unless ref($method);
			eval {$v = ($v * $e->$method) x $v->minv;};
			if ($@){
				warn "mfun: Error $@\n";
				return;
			}
		}
		else{
			warn "mfun: Non invertible matrix in computation of $method\n";
			return;
		}
		return (@dims ==3) ? $v : toreal($v, $tol);
	}
	else{
		$m = $m->r2C unless @dims == 3;
		my ($t, undef, $z, undef, $info) = $m->mschur(1);

		if ($info){
			warn "mfun: Can't compute Schur form\n";
			return;		
		}

		$method = 'PDL::Complex::'.$method unless ref($method);
		($t, $info) = $t->ctrfun(0,$method);
		if($info){
			warn "mfun: Can't compute $method\n";
			return;
		}
		$m = $z x $t x $z->t(1);
		return (@dims ==3) ? $m : toreal($m, $tol);	
	
	}
}

#*mspfun = \&PDL::mspfun;

#sub PDL::mspfun {
#	my ($m, $method, $tol)  = @_;
#	my @dims = $m->dims;
#	barf("mspfun requires a 2-D square matrix")
#		unless( ((@dims == 2) || (@dims == 3)) && $dims[-1] == $dims[-2] );

#	my ($T, $Z, $F, $p, $i, $j, $sden, $s );
#	($T, undef, $Z) = $m->r2C->mschur(1);
 	
#	$F = $T->diagonal(1,2)->$method->diag;
#	for $p (1..($dims[-1] - 1 )){
#		for $i (0..($dims[-1]-$p-1)){
#			$j = $i + $p;
#			$s = $T(,($j),($i))->Cmul($F(,($j),($j))->Csub($F(,($i),($i))));
#			if ($i < ($j-1)){
#				$s = $s + $T(,$i+1:$j-1,($i))->cdot(1, $F(,($j), $i+1:$j-1),1)->Csub($F(,$i+1:$j-1,($i))->cdot(1,$T(,($j), $i+1:$j-1),1));
#			}
#			$sden = $T(,($j),($j))->Csub($T(,($i),($i)));
#			if ($sden != 0){
#	                	$s = $s / $sden;
#  			}
#                       else{
#				barf "Illegal division by zero occured\n";
#                       }
#			$F(,($j),($i)) .= $s;
#        	}
#	}
#	print $F;
#	$m = $Z x $F x $Z->t(1);
#	return (@dims ==3) ? $m : toreal($m, $tol);
#
#}

=head1 TODO

Improve error return and check singularity.
Improve (msqrt,mlog) / r2C

=head1 AUTHOR

Copyright (C) Grégory Vanuxem 2005-2007.

This library is free software; you can redistribute it and/or modify
it under the terms of the artistic license as specified in the Artistic
file.

=cut




;



# Exit with OK status

1;

		   