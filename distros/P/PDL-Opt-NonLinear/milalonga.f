	subroutine milonga (n, m, x, f, g, a, ifree, ele, u,
     *   gaux, aux, d, otro, ap, gamma, beta, ktot, nftot, ngtot,
     *   nintot, nstot, nptot, nbtot, netot, nctot,
     *   eps, maxtang, maxcg, tol, costol, distol, iopt, iophes, iopfac, 
     *   iflag, ambda, rhoinic, rhofac, rho, h, aj,
     *   konout, maxout, ipmil, ipt, ier, qcib, alin, ata, nlin,
     *   evalf, evalg, hessi, hrest, jacobh)

c   Subroutine Milonga:
c
c   This subroutine solves the problem
c                 Minimize f(x)
c      subject to   h(x) = 0
c                   l \leq x \leq u
c
c   where f: R^n ---> R  and  h:R^n ---> R^m   are smooth.
c   
c   The subroutine has been written (beginning september 2002) by 
c   J. M. Martinez with didactical purposes. It uses an augmented
c   Lagrangian approach, which means that, at each outer iteration,
c   the problem
c               Minimize f(x) + h(x)^T y + (rho/2) ||h(x)||^2
c                 subject to l \leq x \leq u
c   
c   and the Lagrange multipliers (y) and the penalty parameter (rho) 
c   are updated before the next outer iteration. 
c   For solving the subproblem above, the subroutine Tango is used.
c   Tango solves minimization problems with box-constraints using 
c   the approach of
c
c   E. G. Birgin and J. M. Mart\'{\i}nez. Large-scale active-set
c   box-constrained optimization method with spectral projected gradients. 
c   {\it Computational Optimization and Applications} 23, pp. 101-125 (2002).
c
c   However, for minimization within the faces of the box, a
c   different algorithm from the one described in this reference is used.
c
c   Calling sequence:
c 
c        call milonga (n, m, x, f, g, a, ifree, ele, u,
c     *   gaux, aux, d, otro, ap, gamma, beta, ktot, nftot, ngtot,
c     *   nintot, nstot, nptot, nbtot, netot, nctot,
c     *   eps, maxtang, maxcg, tol, costol, distol, iopt, iophes, iopfac, 
c     *   iflag, ambda, rhoinic, rhofac, rho, h, aj,
c     *   konout, maxout, ipmil, ipt, ier, qcib, alin, ata, nlin)
c
c   All real parameters are in double precision.
c
c   Parameters:
c   n: number of variables
c   m: number of constraints in h(x)=0.
c   x: (n real positions) Initial point - Final point.
c   f: final value of f(x).
c   g: auxiliar (n real positions)
c   a: auxiliar (n^2 real positions)
c   ifree: auxiliar (n integer positions)
c   ele: lower bounds (n real positions)
c   u: upper bounds (n real positions)
c   gaux: auxiliar (n real positions)
c   aux: auxiliar (n real positions)
c   d: auxiliar (n real positions)
c   otro: auxiliar (n real positions)
c   ap: auxiliar (n real positions)
c  gamma: parameter for Armijo-like searches. Recommended: 1.e-4
c  beta: parameter of Armijo-like searches. Recommended: 0.5
c  ktot: total number of inner (Tango) iterations.
c  nftot: functional evaluations in Tango.
c  ngtot: gradient evaluations in Tango.
c  nintot: number of internal iterations in Tango (iterations where
c          the point remains in the same closed face). 
c  nstot:  number of spg iterations in Tango (iterations where a 
c          closed face is abandoned). 
c  nptot:  number of pure alfa-beta iterations in Tango ( internal iterations
c          where both Armijo (alfa) condition and  beta condition
c          were satisfied with step = 1.
c  nbtot:  number of internal iterations in Tango where backtracking was
c          necessary. 
c  netot:  number of internal 
c          iterations in Tango where extrapolation was tried.
c  nctot:  number of internal iterations in Tango where it was detected
c          that the (approx) Hessian is not positive definite.
c  eps:  small positive parameter for declaring convergence (success).
c        Milonga converges when both the sup-norm of the constraints 
c        and the continuous projected gradient is less than or equal to
c        eps. Tango runs are declared convergent when the supnorm of 
c        the projected gradient is less than or equal to eps.
c  maxtang: maximum number of iterations allowed at each call of Tango.
c  maxcg: maximum number of iterations allowed at each call of the
c         conjugate-gradient method, when this is used. If maxcg=-1, 
c         the maximum number of cg-iterations is automatically set to
c         be the number of free variables.
c  tol: parameter between 0 and 1 used to decide to leave a closed face
c       (using spg) or staying in the face. The face is abandoned when
c       the quotient ginor/gpnor is smaller than tol, where gpnor here
c       is the euclidian norm of the projected gradient and and ginor
c       is the euclidian norm of its projection on the current face.
c  costol: tolerance for cosine. If the cosine of the angle between the
c  search direction and the negative gradient is less than costol, then
c  the search direction is replaced by the negative gradient.
c  distol: when the relative difference between the current point and
c          the backtracked point is smaller than distol, the algorithm
c          Tango returns. This may be because you are using a very 
c          strict criterion (eps) for the projected gradient.
c  iopt: parameter to decide what to do when the Hessian is not positive
c        definite. iopt=1 modifies the diagonal to make it diagonally
c        dominant.   iopt=2 uses conjugate gradients.
c  iophes: Parameter that indicates what type of Hessian is being used.
c        iophes=1 indicates Discrete Hessian
c        iophes=2 indicates that the user provides a subroutine for
c                 computing the analytic Hessian at an arbitrary given
c                 point. In this case, the Hessian of the augmented
c                 Lagrangian used is 
c                 Hessian of the function + rho * A^T A
c                 where A is the Jacobian of the constraints.
c                 This is known as the Gauss-Newton approach in
c   N. Kreji\'c, J. M. Mart\'{\i}nez, M. P. Mello and E. A. Pilotta.
c   Validation of an augmented Lagrangian algorithm with a Gauss-Newton
c   Hessian approximation using a set of hard-spheres problems. 
c   {\it Computational Optimization and
c   Applications}~16,~pp.~247-263~(2000).

c                 See comment of subroutine hessi.
c        iophes=3 indicates "quadratic programming problem"  where you
c        supply the (constant) Hessian and the matrix of constraints 
c        (when m > 0).
c  iopfac: If iopfac=1, an initial Tango iteration is performed with
c        only the sum of squares of constraints as objective function.
c        This option merely changes the initial point to a more feasible
c        one.
c  iflag: output parameter that says what happened in the last iteration
c        of Tango. If iflag=0, Tango returned with the eps-convergence
c        diagnostic. If iflag=1 the maximum allowed Tango-iterations was
c        exhausted. If iflag=2, Tango returned because the relative 
c        difference between a current point and the backtracked point
c        was smaller than distol. 
c  ambda: (m real positions) On input, initial approximation to the
c        Lagrange multipliers. On output, final estimates of the 
c        Lagrange multipliers. 
c  rhoinic: initial value for the penalty parameter.
c  rhofac: factor for which the penalty parameter is multiplied after
c          each outer iteration, if necessary. By mystical reasons one
c          usually sets rhofac = 10.
c  rho: final value of the penalty parameter used.
c  h: (m real positions) On output, values of the constraints h(x).
c  aj: (m * n  real positions) Auxiliar array, used to stored the
c      Jacobian of the constraints. Please, when m=0, declare in the
c      main program dimension aj(1) (or any other natural number 
c      greater than 1, instead of 1) in order to avoid compiling errors.
c  konout: effective number of outer (milonga) iterations performed.
c  maxout: maximum number of outer iterations allowed. Many times, when
c      this number is exceeded the reason is that the problem is 
c      infeasible.
c  ipmil: parameter that commands printing of milonga. Milonga prints
c      in the screen and in the file milonga.out. If ipmil < 0, nothing
c      is printed. If ipmil=0 only initial and final information is 
c      printed. If ipmil > 0 information of milonga is printed every 
c      ipmil outer iterations. If m=0 the value of ipmil is irrelevant
c      and all printings are commanded by ipt.
c  ipt: parameter that commands printing of Tango. Tango prints
c      in the screen and in the file milonga.out. If ipt < 0, nothing
c      is printed. If ipt=0 only initial and final information is 
c      printed. If ipt > 0 information of milonga is printed every 
c      ipt Tango-iterations.
c  ier: output parameter that says what happened. If ier=0 convergence
c       occurred in the sense that both the supnorm of the constraints
c       and the supnorm of the projected gradient are smaller than or
c       equal to eps. If ier=1 the number of outer iterations was 
c       exhausted.
c  qcib: Assume that your problem is of the form 
c        Minimize x^T Q x + c^T x   subject to   A x = b.
c        You can deal with this problem as an ordinary problem with 
c        ordinary objective function and constraints. But Milonga
c        allows you to take advantage with (part of) the structure
c        of the problem. If you want to take such advantage, set 
c        iophes = 3 (see comment of iophes above) and provide the 
c        matrix Q in the array qcib. So, qcib must be a symmetric
c        matrix that must be declared in the main program as having
c        a number of rows that also must be informed to Milonga as 
c        being equal to nlin. That is, the parameter nlin must be 
c        the exact number of rows declared for qcib in the main program.
c        Of course, qcib must have at least n columns.
c  alin: In the case that described in the comment of qcib you must
c        also provide the matrix A. This matrix must be given in the
c        array alin. However, unlike the storage of qcib, alin must be
c        stored as a single vector in the main program. The vector 
c        must store the elementes of A, in columnwise form. Of course,
c        alin must have at least m*n entries.
c  ata:  Again in the case described in the comment of qcib, Milonga
c        needs an auxiliary matrix called ata. You must declare this 
c        matrix as having exactly nlin rows and at least n columns. 
c  nlin: on entry, this must be the exact number of rows declared for
c        qcib and ata in the main program.
c
c        The user must also provide four subroutines that give,
c        respectively, the objective function value, its gradient,
c        the constraints and the Jacobian of the constraints.
c        Let us now describe how these subroutines must be.
c
c  Subroutine that computes the objective function value:
c  Must have the form:
c
c  Subroutine evalf (n, x, f)
c  implicit double precision (a-h,o-z)
c  dimension x(n)
c  .....
c  return
c  end
c
c  where n is the number of variables, x is the point where f(x) must
c  be computed and f (the output) is the functional value. The user
c  must code the subroutine. However, in the case "iophes=3"  the user
c  can take advantage of the situation merely coding
c
c  Subroutine evalf (n, x, f)
c  implicit double precision (a-h,o-z)
c  dimension x(n)
c  dimension aux(134)   (say)
c  ..............
c  nlin = 58        (say)
c	call funquad (n, qcib, x, ccib, f, aux, nlin)
c	return
c  end
c
c  In fact, funquad is an internal routine of Milonga. Observe that the
c  information qcib and ccib must be passed through common. I'm
c  sorry. This will be improved in the future. 
c
c  Subroutine that computes the gradient of the objective function:
c  Must have the form:
c
c  Subroutine evalg (n, x, g)
c  implicit double precision (a-h, o-z)
c  dimension x(n), g(n)
c ...............
c  return
c  end
c
c  In this subroutine, n is the number of variables, x is the point where
c  the gradient must be computed and g is the computed gradient. 
c
c  As in the case of evalf, in the case "iophes=3"  the user
c  can take advantage of the situation merely coding
c
c  Subroutine evalg (n, x, g)
c  implicit double precision (a-h,o-z)
c  dimension x(n)
c  ..............
c  nlin = 58        (say)
c  call graquad (n, x, qcib, ccib, g, nlin)
c  return
c  end
c
c  In fact, graquad is an internal routine of Milonga. Observe that the
c  information qcib and ccib must be passed through common. I'm
c  sorry. This will be improved in the future. 
c
c  Subroutine that computes the constraints h(x):
c  Must have the form:
c  Subroutine hrest (m, n, x, h)
c  implicit double precision (a-h,o-z)
c  dimension x(n), h(m)
c  .....
c  return
c  end
c
c  where n is the number of variables, m is the number of constraints
c  x is the point where the constraints must be computed and h
c  is the vector of constraints. No provision is taken, up to now, to
c  take advantage of linear constraints here.
c
c  Subroutine that computes the Jacobian of the constraints:
c  Must have the form:
c 	subroutine jacobh (m, n, x, aj)
c	implicit double precision (a-h, o-z)
c	dimension x(n), aj(m, n)
c  
c  where n is the number of variables, m is the number of constraints
c  x is the point where the constraints must be computed and the matrix
c  aj must be computed in order to store the derivatives of the constraints.
c  aj(i, j) must be the derivative of the i-th constraint with respect
c  to the j-th variable. No provision is taken, up to now, to
c  take advantage of linear constraints here.
c
c  Subroutine that computes the Hessian of the objective function:
c  The user must code this subroutine only if iophes=2. 
c  Must have the form:
c         subroutine hessi (n, x, hess)
c         implicit double precision (a-h,o-z)
c         dimension x(n), hess(n, n)	
c         ---------
c         return
c         end
c  In fact, observe that this subroutine, exactly in the way described
c  above, is part of this package. You must fill the dashed lines if 
c  you provide the Hessian. 
c



	implicit double precision (a-h,o-z)
	external funtan,gratan,sumsq,grasum
	external evalf,evalg,hrest,hessi, jacobh

	dimension a(n, n)
	dimension ifree(n)
	dimension ele(n), u(n)
	dimension x(n), g(n)
	dimension gaux(n), aux(n)
	dimension d(n)
	dimension otro(n)
	dimension ap(n)
	dimension ambda(m)
	dimension h(m)
	dimension aj(m, n)
	dimension qcib(nlin, *)
	dimension alin(*)
	dimension ata(nlin, *)

	n10 = min0(n, 10)
	m10 = min0(m, 10)

	if(m.gt.0) then

        	if(rhoinic.eq.0) then
	        write(*, *)' Error. Initial penalty parameter null.'
	        stop
	        endif

	rho = rhoinic
	
	   if(iophes.eq.3) then
	   do i = 1, n
	   do j = 1, n
	   ata(i, j) = 0.d0
	   do k = 1, m
	   ata(i, j) = ata(i, j) + alin((i-1)*m+k) * alin((j-1)*m+k)
	   end do
	   end do
	   end do
	   end if
	endif

c  Checking box
	do i = 1, n
	x(i) = dmax1(ele(i), dmin1(x(i), u(i)))
	end do

	if(m.eq.0) then
 	call tango (funtan, gratan, n, x, f, g, a, ifree, ele, u,
     *   gaux, aux, d, otro, ap, gamma, beta, kon, nef, neg, nint,
     *   nspg, npur, nback, nextr, ncor, nfsmal, 
     *   eps, maxtang, maxcg, tol, costol, distol, iopt, iophes, 
     *   iflag, gpnor, m, ambda, rho, h, aj, ipt, qcib, ata, nlin,
     *   evalf, evalg, hessi, hrest, jacobh)
	return
	endif
	
c  Find a better initial point

	if(iopfac.eq.1) then
 	call tango (sumsq, grasum, n, x, f, g, a, ifree, ele, u,
     *   gaux, aux, d, otro, ap, gamma, beta, kon, nef, neg, nint,
     *   nspg, npur, nback, nextr, ncor, nfsmal, 
     *   eps, maxtang, maxcg, tol, costol, distol, iopt, iophes, 
     *   iflag, gpnor, m, ambda, rho, h, aj, ipt, qcib, ata, nlin,
     *   evalf, evalg, hessi, hrest, jacobh)
	endif

	ktot = 0
	nftot = 0
	ngtot = 0
	nintot = 0
	nstot = 0
	nptot = 0
	nbtot = 0
	netot = 0
	nctot = 0
	nfstot = 0

	konout = 0

c  Initial evaluation of constraints



	call hrest(m, n, x, h)


c   Compute sup norm of constraints
	hnor = 0.d0
	do i = 1, m
	hnor = dmax1(hnor, dabs(h(i)))
	end do


	call jacobh (m, n, x, aj)


	call evalg(n, x, g)


	do j = 1, n
	do i = 1, m
	g(j) = g(j) + aj(i, j) * ambda(i)
	end do
	end do


	gpnor = 0.d0
	do i = 1, n
	z = x(i) - g(i)
	z = dmax1(ele(i), dmin1(u(i), z))
	z = dabs(z - x(i))
	gpnor = dmax1(z, gpnor)
	end do



1	continue

	call evalf (n, x, f)

	if(ipmil.ge.0) then
	write(10, *)
	write(10, *)' Milonga (Outer) iteration:', konout
	write(10, *)' Current point:'
	write(10, *)(x(i), i = 1, n10)
	write(10, *)' Objective function:', f
	write(10, *)' Sup norm of the constraints:', hnor
	write(10, *)' Multipliers:'	
	write(10, *) (ambda(i),i=1,m10)
	write(10, *)' Sup norm of projected gradient of Lagrangian:',
     *                gpnor
	


	write(*, *)
	write(*, *)' Milonga (Outer) iteration:', konout
	write(*, *)' Current point:'
	write(*, *)(x(i), i = 1, n10)
	write(*, *)' Objective function:', f
	write(*, *)' Sup norm of the constraints:', hnor
	write(*, *)' Multipliers:'	
	write(*, *) (ambda(i),i=1,m10)
	write(*, *)' Sup norm of projected gradient of Lagrangian:',
     *                gpnor
	endif

	if(dmax1(hnor, gpnor).le.eps) then
	ier = 0
	if(ipmil.ge.0) then
	write(10, *)
	write(10, *)' Solution found. f(x)=',f
	write(*, *)
	write(*, *)' Solution found. f(x)=',f
	write(10, *)' Number of inner (Tango) iterations:', ktot
	write(10, *)' Function evaluations in Tango:', nftot
	write(10, *)' Gradient evaluations in Tango:', ngtot
	write(10, *)' Number of internal iterations:', nintot
	write(10, *)' Number of spg iterations:', nstot
	write(10, *)' Current points where nfree < m:', nfstot
	write(10, *)' Number of pure alfa-beta iterations:', nptot
	write(10, *)' Number of internals with backtracking:',nbtot
	write(10, *)' Number of extrapolations tried:', netot
	write(10, *)' Number of nonsemiposdef Hessians:', nctot

	write(*, *)' Number of inner (Tango) iterations:', ktot
	write(*, *)' Function evaluations in Tango:', nftot
	write(*, *)' Gradient evaluations in Tango:', ngtot
	write(*, *)' Number of internal iterations:', nintot
	write(*, *)' Number of spg iterations:', nstot
	write(*, *)' Current points where nfree < m:', nfstot
	write(*, *)' Number of pure alfa-beta iterations:', nptot
	write(*, *)' Number of internals with backtracking:',nbtot
	write(*, *)' Number of extrapolations tried:', netot
	write(*, *)' Number of non semiposdef Hessians:', nctot
	endif

	return
	endif
	
	if(konout.ge.maxout) then
	ier = 1
	if(ipmil.ge.0) then
	write(10, *)
	write(10, *)' Exceeded allowed outer iterations'
	write(*, *)
	write(*, *)' Exceeded allowed outer iterations'
	write(10, *)' Number of inner (Tango) iterations:', ktot
	write(10, *)' Function evaluations in Tango:', nftot
	write(10, *)' Gradient evaluations in Tango:', ngtot
	write(10, *)' Number of internal iterations:', nintot
	write(10, *)' Current points where to nfree < m:', nstot
	write(10, *)' Spg iterations due to nfree small:', nfstot
	write(10, *)' Number of pure alfa-beta iterations:', nptot
	write(10, *)' Number of internals with backtracking:',nbtot
	write(10, *)' Number of extrapolations tried:', netot
	write(10, *)' Number of nonsemiposdef Hessians:', nctot
	
	write(*, *)' Number of inner (Tango) iterations:', ktot
	write(*, *)' Function evaluations in Tango:', nftot
	write(*, *)' Gradient evaluations in Tango:', ngtot
	write(*, *)' Number of internal iterations:', nintot
	write(*, *)' Number of spg iterations:', nstot
	write(*, *)' Current points where to nfree < m:', nfstot
	write(*, *)' Number of pure alfa-beta iterations:', nptot
	write(*, *)' Number of internals with backtracking:',nbtot
	write(*, *)' Number of extrapolations tried:', netot
	write(*, *)' Number of non semiposdef Hessians:', nctot
	endif

	return
	endif

	if(ipmil.ge.0) then
	write(10, *)' Penalty parameter for the next iteration:',rho
	write(*, *)' Penalty parameter for the next iteration:',rho
	endif

	hnoran = hnor


 	call tango (funtan, gratan, n, x, f, g, a, ifree, ele, u,
     *   gaux, aux, d, otro, ap, gamma, beta, kon, nef, neg, nint,
     *   nspg, npur, nback, nextr, ncor, nfsmal, 
     *   eps, maxtang, maxcg, tol, costol, distol, iopt, iophes, 
     *   iflag, gpnor, m, ambda, rho, h, aj, ipt, qcib, ata, nlin,
     *   evalf, evalg, hessi, hrest, jacobh)


	ktot = ktot + kon
	nftot = nftot + nef
	ngtot = ngtot + neg
	nintot = nintot + nint
	nstot = nstot + nspg
	nptot = nptot + npur
	nbtot = nbtot + nback
	netot = netot + nextr
	nctot = nctot + ncor
	nfstot = nfstot + nfsmal


	call hrest (m, n, x, h)

	hnor = 0.d0
	do i = 1, m
	hnor = dmax1(hnor, dabs(h(i)))
	end do
	

	if(gpnor.le.eps) then
	if(ipmil.ge.0) then
	write(10, *)' Tango ran with success'
	write(*, *)' Tango ran with success'
	endif
	do i = 1, m
	ambda(i) = ambda(i) + rho * h(i)
	end do
	endif

	if(hnor.gt.hnoran/10.d0) then
	rho = rhofac * rho
	endif
	
	konout = konout + 1
	go to 1
	
	end

	

	subroutine tango (funtan, gratan, n, x, f, g, a, ifree, ele, u,
     *   gaux, aux, d, otro, ap, gamma, beta, kon, nef, neg, nint,
     *   nspg, npur, nback, nextr, ncor, nfsmal, 
     *   eps, max, maxcg, tol, costol, distol, iopt, iophes, 
     *   iflag, gpnor, m, ambda, rho, h, aj, ipt, qcib, ata, nlin,
     *   evalf, evalg, hessi, hrest, jacobh)

	implicit double precision (a-h,o-z)
	external funtan, gratan, evalf, evalg, hessi, hrest, jacobh
	dimension a(n, n)
	dimension ifree(n)
	dimension ele(n), u(n)
	dimension x(n), g(n)
	dimension gaux(n), aux(n)
	dimension d(n)
	dimension otro(n)
	dimension ap(n)
	dimension ambda(m)
	dimension h(m)
	dimension aj(m, n)
	dimension ata(nlin, *), qcib(nlin, *)
c
c  Tango is a subroutine for box-constrained minimization written
c  by J. M. Martinez with didactical purposes in the context of 
c  the course Metodos Computacionais de Otimizacao at the 
c  University of Campinas
c  The purpose is to minimize f(x) subject to bounds on the variables
c  The subroutine uses the active set strategy and line searches 
c  described in
c  E. G. Birgin and J. M. Martinez (2002) ``Large-scale active set
c  box-constrained optimization method with spectral projected 
c  gradients'',  Computational Optimization and Applications 23, 
c  pp. 101-125 (2002).
c  However, the search directions are different from the ones defined
c  in that paper, which is devoted to large-scale problems.
c  In Tango the search directions are Newton directions inside the
c  faces and are corrected in different ways when the Hessians are not
c  positive definite.
c  Parameters:
c  n: number of variables
c  x: initial point - final point
c  f: final value of the objective function
c  g: final gradient
c  a: auxiliar array of n**2 positions for internal storage of the Hessian
c  ifree: auxiliar integer array of n positions (for free variables)
c  ele, u: lower and upper bounds
c  gaux, aux, d, otro, ap: auxiliar double precision arrays n positions
c  beta: parameter for line search. Default: 0.5
c  kon: number of iterations
c  nef: number of function evaluations
c  neg: number of gradient evaluations
c  nint: number of iterations within the faces
c  nspg: number of iterations that leave the current face (spg iterations)
c  npur: number of iterations where the line search stopped at the first
c        trial (alfa-beta iterations)
c  nback: number of iterations where backtracking was necessary
c  nextr: number of iterations where extrapolation was tried
c  ncor: number of iterations where the Hessian was not positive definite
c  eps: small number for convergence (projected gradient small)
c  max: maximum number of iterations allowed
c  tol: parameter to decide leaving faces. Default: 0.1
c  costol: tolerance for cosine. If the cosine of the angle between the
c  search direction and the negative gradient is less than costol, then
c  the search direction is replaced by the negative gradient.
c  iopt: parameter to decide what to do when the Hessian is not positive
c        definite. iopt=1 modifies the diagonal to make it diagonally
c        dominant.   iopt=2 uses conjugate gradients.
c  iflag: output parameter that says what happened.
c  

c	write(10, *)' In tango'
c	write(10, *)' Half-Hessian of the quadratic:'
c	do i = 1, n
c	write(10, *) (qcib(i, j), j=1,n)
c	end do
	

c  
c  Initialization
	tol2 = tol * tol
c  itipo is the type of iterate. 0 means initial point
	itipo = 0
	kon = 0
	nint = 0
	nspg = 0
	npur = 0
	nback = 0
	nextr = 0
	ncor = 0
	nfsmal = 0

c  Initial evaluation of function and gradient
	call funtan(m, n, x, ambda, rho, h, f,evalf,hrest)
	call gratan (m, n, x, ambda, rho, h, aj, g, evalg,hrest,jacobh)
	nef = 1
	neg = 1



c  Here begins the loop
c  Compute free variables
1	nfree = 0
c  Project initial point on the box

	do i = 1, n
	x(i) = dmin1(u(i), dmax1(ele(i), x(i)))
	if(x(i).gt.ele(i).and.x(i).lt.u(i)) then
	nfree = nfree + 1
	ifree(nfree) = i
	end if
	end do

c  Compute norms of projected gradient and internal gradient
	gpnor = 0.d0
	ginor2 = 0.d0
	gpnor2 = 0.d0

	do i = 1, n
	z = x(i) - g(i)
	z = dmin1(u(i), dmax1(ele(i), z))
	z = z - x(i)
	z2 = z * z
	gpnor = dmax1(gpnor, dabs(z))
	gpnor2 = gpnor2 + z2
	if(x(i).gt.ele(i).and.x(i).lt.u(i)) then
	ginor2 = ginor2 + z2
	endif
	end do

c  Printing
	if(ipt.gt.0.and.mod(kon,ipt).eq.0) then
	
	write(10, *)
	write(10, *)' Tango Iteration ', kon
	if(itipo.ne.0) then
	if(itipo.eq.1) then
	write(10, *)' Point obtained in the same closed face'
	else
	write(10, *)' Point obtained by SPG iteration'
	endif
	endif
	write(10, *)' Point:'
	write(10, *) (x(i),i=1,n)
	write(10, *)' f(x) =', f
	write(10, *)' Gradient:'
	write(10, *) (g(i),i=1,n)
	write(10, *)' Sup norm of projected gradient:', gpnor
	write(10, *)' Number of free variables:', nfree
	if(nfree.gt.0) then
	write(10, *)' Free variables:', (ifree(i),i=1,nfree)
	endif
	write(10, *)' Function evaluations:', nef,
     *   ' Gradient evaluations:', neg
	write(10, *)' Number of internal iterations:', nint
	write(10, *)' Number of spg iterations:', nspg
	write(10, *)' Current points where to nfree < m:', nfsmal
	write(10, *)' Number of pure alfa-beta iterations:', npur
	write(10, *)' Number of internals with backtracking:',nback
	write(10, *)' Number of extrapolations tried:', nextr
	write(10, *)' Number of nonsemiposdef Hessians:', ncor
	
	write(10, *)
	write(*, *)
	write(*, *)' Tango Iteration ', kon
	if(itipo.ne.0) then
	if(itipo.eq.1) then
	write(*, *)' Point obtained in the same closed face'
	else
	write(*, *)' Point obtained by SPG iteration'
	endif
	endif
	write(*, *)' Point:'
	write(*, *) (x(i),i=1,n)
	write(*, *)' f(x) =', f
	write(*, *)' Gradient:'
	write(*, *) (g(i),i=1,n)
	write(*, *)' Sup norm of projected gradient:', gpnor
	write(*, *)' Number of free variables:', nfree
	if(nfree.gt.0) then
	write(*, *)' Free variables:', (ifree(i),i=1,nfree)
	endif
	write(*, *)' Function evaluations:', nef,
     *   ' Gradient evaluations:', neg
	write(*, *)' Number of internal iterations:', nint
	write(*, *)' Number of spg iterations:', nspg
	write(*, *)' Current points where to nfree < m:', nfsmal
	write(*, *)' Number of pure alfa-beta iterations:', npur
	write(*, *)' Number of internals with backtracking:',nback
	write(*, *)' Number of extrapolations tried:', nextr
	write(*, *)' Number of non semiposdef Hessians:', ncor
	write(*, *)
	endif




c   Stopping criteria
	itipo = 1
	if(gpnor.le.eps) then
	iflag = 0
	if(ipt.ge.0) then
	write(10, *) ' Convergence: small sup norm of proj. gradient'
	write(*, *) ' Convergence: small sup norm of proj. gradient'
	endif
	return
	endif

	if(kon.gt.max) then
	iflag = 1
	if(ipt.ge.0) then
	write(10, *)' Maximum number of iterations exhausted'
	write(*, *)' Maximum number of iterations exhausted'
	endif
	return
	endif


c   Abandon the face if the number of free variables is smaller than
c   the number of constraints
	
	if(m.gt.nfree) nfsmal = nfsmal + 1

c   Decision about giving up the current face or not
c   If the norm of internal gradient is large in comparison to the 
c   projected gradient we keep the same face
c


	if(ginor2.le.tol2*gpnor2) then 
c   Abandon the face using an spg iteration
c   itipo = 2 means that the following point leaves the current face

	itipo = 2
c   call the subroutine that abandons the face (spg)
	call giveup (funtan, gratan, 
     *      n, x, f, g, ele, u, nef, neg, gamma, 
     *      aux, gaux, d, m, ambda, rho, h, aj, evalf,evalg,hrest,
     *      jacobh)
	kon = kon + 1
	nspg = nspg + 1
	go to 1
	endif



c Check if we have at least one free variable
	if(nfree.lt.1) then
	write(*, *)' There are no free variables. Something wrong.'
        write(*, *)' Probably, the gradient was evaluated at a'
        write(*, *)' Forbidden point, given not-a-number as result.'
	stop
	endif

c Check if x is in the box
	do i = 1, n
	if(x(i).gt.u(i).or.x(i).lt.ele(i)) then
	write(*, *) ' x out of bounds'
	stop
	endif
	end do



c Check free variables
	do i = 1, nfree
	ii = ifree(i)
	if(x(ii).ge.u(ii).or.x(ii).le.ele(ii)) then
	write(*, *)' The free variable', ii, ' is not free'
	stop
	endif
	end do
	nint = nint + 1

	   if(iophes.eq.2) then
	   call hessi (n, x, a)

c	write(10, *)' Hessian:'
c	do i = 1, n
c	write(10, *) (a(i, j), j=1,n)
c	end do
	
        	do i = 1, nfree
	        do j = 1, nfree
	        ii = ifree(i)
	        jj = ifree(j)
	        qcib(i, j) = a(ii, jj)
	        end do
	        end do

c	write (10, *)' Free variables:'
c	write(10, *) (ifree(i), i=1,nfree)

c	write(10, *)' Reduced Hessian:'
c	do i = 1, nfree
c	write(10, *) (qcib(i, j), j=1,nfree)
c	end do


	   if(m.gt.0) then
	   call jacobh(m, n, x, aj)


c	write(10, *)' Point where I compute Jacobian:'
c	write(10, *) (x(i), i=1,n)
c	write(10, *) ' Jacobian:'
c	do i = 1, m
c	write(10, *) (aj(i, j), j=1,n)
c	end do

	   do i = 1, n
	   do j = 1, n
	   ata(i, j) = 0.d0
	   do k = 1, m
	   ata(i, j) = ata(i, j) + aj(k, i) * aj(k, j)
	   end do
	   end do
	   end do


c	write(10, *)' Reduced Hessian (qcib) de nuevo:'
c	do i = 1, nfree
c	write(10, *) (qcib(i, j), j=1,nfree)
c	end do
c	write(10, *) ' J^T J (ata):'
c	do i = 1, n
c	write(10, *) (ata(i, j), j=1,n)
c	end do
c	write(10, *)' rho =', rho

        	do i = 1, nfree
	        do j = 1, nfree
	        ii = ifree(i)
	        jj = ifree(j)
	        
c	        write(10, *)' i = ', i, ' j =', j
c		write(10, *)' ii = ', ii,' jj = ', jj
c		write(10, *)' qcib(i, j)=', qcib(i, j)
c		write(10, *)' rho = ', rho
c		write(10, *)' ata(ii, jj) =', ata(ii, jj)
		
	        qcib(i, j) = qcib(i, j) + rho * ata(ii, jj)

c		write(10, *)' qcib(i,j)+rho*ata(ii,jj)=',qcib(i,j)
c		write(10, *)' qcib(2, 1) =', qcib(2, 1)

	        end do
	        end do

c	write(10, *) ' Hessian gaussnewton (nuevo qcib):'
c	do i = 1, nfree
c	write(10, *) (qcib(i, j), j=1,nfree)
c	end do



	   end if
c  This endif corresponds to if(m.gt.0)

	do i = 1, nfree
	do j = 1, nfree
	a(i, j) = qcib(i, j) 
	end do
	end do


c	write(10, *) ' Hessian gaussnewton:'
c
c	do i = 1, nfree
c	write(10, *) (a(i, j), j=1,nfree)
c	end do
c
c	stop


	   endif
c  This endif corresponds to if(iophes.eq.2n)		


	if(iophes.eq.3) then
	if(m.gt.0) then
	do i = 1, nfree
	do j = 1, nfree
	ii = ifree(i)
	jj = ifree(j)
	a(i, j) = 2.d0 * qcib(ii, jj) + rho * ata(ii, jj)
	end do
	end do
	else
	do i = 1, nfree
	do j = 1, nfree
	ii = ifree(i)
	jj = ifree(j)
	a(i, j) = 2.d0 * qcib(ii, jj) 
	end do
	end do
	endif


c	write(10, *)' Half-Hessian of the quadratic:'
c	do i = 1, n
c	write(10, *) (qcib(i, j), j=1,n)
c	end do
c
c	write(10, *)' quadratic hessian of the augmented lag.:'
c	do i = 1, nfree
c	write(10, *)(a(i, j), j=1,nfree)
c	end do



	endif


	if(iophes.eq.1) then
c Compute the discrete Hessian


c	write(10, *)' Point where I compute discrete Hessian:'
c	write(10, *) (x(i), i = 1, n)
c	write(10, *)' Lagrange multipliers:'
c	write(10, *) (ambda(i), i=1,m)
c	write(10, *)' gradient in basic point:'
c	write(10, *) (g(i),i=1,n)

	do j = 1, nfree
	jj = ifree(j)
	hh = dmax1(1.d-10, dabs(x(jj))*1.d-7)
	if(x(jj).lt.0.d0) hh = - hh
	save = x(jj)
	x(jj) = x(jj) + hh


       call gratan (m, n, x, ambda, rho, h, aj, gaux, evalg,hrest,
     *	jacobh)

c	write(10, *)' j =', j
c	write(10, *)' x =', (x(i),i=1,n)
c	write(10, *)' lambda:', (ambda(i),i=1,m)
c	write(10, *)' Jacobian:'
c	do i =1, m
c	write(10, *) (aj(i,jjj),jjj=1,n)
c	end do
c	write(10, *)' h increment:', hh
c	write(10, *)' Auxiliar gradient:'
c	write(10, *)(gaux(i), i=1,n)

	do i = 1, nfree
	a(i, j) = (gaux(ifree(i)) - g(ifree(i)))/hh
	end do


	x(jj) = save
	end do



c	write(10, *)' Hessian before simetrization:'
c	do i = 1, nfree
c	write(10, *) (a(i, j), j=1,nfree)
c	end do
c	write(10, *)

c  Simetrization
	if(nfree.ne.1) then
	do i = 2, nfree
	do j = 1, i-1
	a(i, j) = (a(i, j) + a(j, i))/2.d0
	a(j, i) = a(i, j)
	end do
	end do
	endif



c	write(10, *)' Hessian after simetrization:'
c	do i = 1, nfree
c	write(10, *) (a(i, j), j=1,nfree)
c	end do
c	write(10, *)

c	write(10, *)' discrete hessian:'
c	do i = 1, nfree
c	write(10, *)(a(i, j), j=1,nfree)
c	end do



	endif
c   This endif corresponds to if(iophes.eq.1) (Discrete Hessian option)

c
c  iopt=1 is the option that corrects the diagonal of the Hessian if
c  the Hessian is not positive definite
c
	if(iopt.eq.1) then
	icore = 0
c  Test a null Hessian
	anor = 0.d0
	do i = 1, nfree
	do j = 1, i
	anor = dmax1(anor, dabs(a(i, j)))
	end do
	end do



c  Detect null diagonal elements
	corret = 0.d0
	diamin = 1.d0
	do i = 1, nfree
	if(a(i,i).lt.diamin) diamin = a(i,i)
	end do
	if(diamin.le.0.d0) then
	corret = -diamin + 1.d-8 * anor
	do i = 1, n
	a(i, i) = a(i, i) + corret
	end do



c	write(10, *)' Maximum element of Hessian:', anor
c	write(10, *)' Diagonal corrected by ', corret
	icore = 1
	endif
	
		


c  Null Hessian replaced by Identity
	if(anor.eq.0.d0) then
	icore = 1
	anor = 1.d0
	do i = 1, nfree
	a(i, i) = 1.d0
	end do
	endif


c  Factorization of the Hessian
	call chole(nfree, a, ier, aux, n)



	if(ier.gt.0) then
    	icore = 1
c  Modify the Hessian because it is not positive definite
          if(nfree.gt.1) then
	  defic = 0.d0
	  do i = 1, nfree
	  acum = 0.d0
	  do j = 1, nfree
	  if(i.ne.j) acum = acum + dabs(a(i, j))
	  end do
	  defic = dmax1(defic, dmax1(0.d0, acum - a(i, i)))
	  end do

c  Correct the diagonal of the Hessian to make it positive definite

         correc = defic + 1.d-8 * anor
	  do i = 1, nfree
	  a(i, i) = a(i, i) + correc
	  end do
	 corret = corret + correc 

         else
	  a(1, 1) = 1.d0
	  corret = 1.d0
	  endif

c	write(10, *)' Corrected Hessian:'
c	do i = 1, nfree
c	write(10, *) (a(i, j), j=1,nfree)
c	end do
c	write(10, *)

c	write(10, *)' Total diagonal correction:', corret


c  Re-factorize
	call chole(nfree, a, ier, aux, n)
	if(ier.ne.0) then
	write(*, *)' Something wrong. Modified Hessian not pos.def.'
	stop
	endif

	endif

c Solve the Newtonian system


	do i = 1, nfree
	ii = ifree(i)
	gaux(i) = -g(ii)
	end do

	
	
	call sicho (nfree, a, d, gaux, aux, n)


	if(icore.eq.1) ncor = ncor + 1

	endif
c  This endif corresponds to    - if (iopt.eq.1) -
c  End of the option iopt=1 . The output of this option is the
c  ``newtonian'' direction d

c  When iopt=2 and we detect a nonpositive definite Hessian, we
c  try conjugate gradients.
c
	if(iopt.eq.2) then
	do i = 1, nfree
	ii = ifree(i)
	gaux(i) = - g(ii)
	end do
	call chole (nfree, a, iercho, aux, n)
	if(iercho.ne.0) then
	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' The Hessian is not pos.def. Try CG'
	endif
	endif
	if(iercho.eq.0) then
	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' The Hessian is pos. def. '
	endif
	call sicho (nfree, a, d, gaux, aux, n)
	else
c  The Hessian is not positive definite. 
	ncor = ncor + 1
	
	if(maxcg.eq.-1) maxcg = nfree

c	write(10, *) ' Termino independiente en cg :'
c	write(10, *) (gaux(i), i=1,nfree)

	call milalonga_cg (nfree, a, gaux, d, otro, aux, ap, n, iercg,
     *     koncg, maxcg)
c   The conjugate gradient subroutine finished with a direction d that
c   minimizes the quadratic in the Krylov subspace and a direction aux
c   where the quadratic has nonpositive curvature (when iercg=1)
c
	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' Output of CG. iercg =', iercg,' cg-iterations:',
     *    koncg
	write(10, *)' Quadratic minimizer in Krylov subspace:'
	write(10, *) (d(i), i = 1, nfree)
	endif
	if(iercg.eq.1) then
	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' CG finished finding a nonpositive curvature'
	endif
	pesca = 0.d0
	do i = 1, nfree
	ii = ifree(i)
	pesca = pesca + d(i) * g(ii)
	end do
c  This scalar product must be nonpositive, in theory.

	if(pesca.lt.0.d0) then
c	write(10, *)' Krylov direction is a descent direction'
c	write(10, *)' directional derivative:', pesca

c  The Krylov direction d is a descent direction. 

	delta  = 0.d0
	do i = 1, nfree
	delta = dmax1(delta, dabs(d(i)))
	delta = dmax1(delta, dabs(x(ifree(i))))
	end do

	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' Nonpositive curvature direction:'
	write(10, *) (aux(i), i=1,nfree)
	endif

	p1 = 0.d0
	do i = 1, nfree
	p1 = p1 + otro(i)*aux(i)
	end do


	if(p1.lt.0.d0) then
	do i = 1, nfree
	aux(i) = -aux(i)
	end do
	endif

	
	if(p1.ne.0.d0) then
	amor = 0.d0
	do i = 1, nfree
	amor = dmax1(amor, dabs(aux(i)))
	end do
	if(amor.gt.delta) then
	amor = delta/amor
	do i = 1, nfree
	aux(i) = aux(i) * amor
	end do
	endif

	do i = 1, nfree
	aux(i) = d(i) + aux(i)
	end do
	p1 = 0.d0
	do i = 1, nfree
	ii = ifree(i)
	p1 = p1 + aux(i) * g(ii)
	end do

	if(p1.ge.0.d0) then
	z = pesca / (pesca - p1)
	z = z/2.d0
	do i = 1, nfree
	d(i) = d(i) + z * (aux(i) - d(i))
	end do
	else
	do i = 1, nfree
	d(i) = aux(i)
	end do
	endif

	endif
c   This endif corresponds to - if(p1.ne.0.d0) - 





	else
c  This else corresponds to - if(pesca.lt.0.d0) -

c	write(10, *)' Krylov direction is not a descent direction'
c	write(10, *)' directional derivative:', pesca
c	write(10, *)' Taken d = -g'

	do i = 1, nfree
	ii = ifree(i)
	d(i) = - g(ii)
	end do

	endif
c  This endif corresponds to - if(pesca.lt.0.d0) - else

	endif
c  This endif corresponds to - if(iercg.eq.1) - ( after  call cg )

	endif
c  This endif corresponds to - if(iercho.eq.0  -  else  -


	endif
c  This endif corresponds to    - if(iopt.eq.2) -

c  d is the Newton direction (only free variables)

	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' Newton direction:'
	
	write(10, *) (d(i), i=1,nfree)
	endif


	dnor = 0.d0
	do i = 1, nfree
	dnor = dmax1(dnor, dabs(d(i)))
	end do

c	write(10, *)' Sup norm of Newton direction:', dnor

	if(dnor.eq.0.d0) then
	write(*, *)' Something wrong. Newton direction null'
	stop
	endif


	do i = 1, n
	aux(i) = x(i)
	otro(i) = x(i)
	end do


	dmin = dnor
	do i = 1, nfree
	if(d(i).ne.0.d0) then
	dmin = dmin1(dmin, dabs(d(i)))
	endif
	end do


c  Check whether the point is interior or not
	inter = 1
	do i = 1, nfree
	ii = ifree(i)
	z = x(ii) + d(i)
	if(z.ge.u(ii).or.z.le.ele(ii)) inter = 0
	end do


c  Compute alfamax
	alfamax = 0.d0
	do i = 1, nfree
	ii = ifree(i)
	alfamax = dmax1(alfamax, (u(ii)-x(ii))/dmin)
	alfamax = dmax1(alfamax, (x(ii)-ele(ii))/dmin)
	end do
	

	do i = 1, nfree
	ii = ifree(i)
	if(d(i).ne.0.d0) then
	  if(d(i).gt.0.d0) then
	  alfamax = dmin1(alfamax, (u(ii)-x(ii))/d(i))
	  else
	  alfamax = dmin1(alfamax, (ele(ii)-x(ii))/d(i))
	  endif
	endif
	end do

	if(inter.eq.0) alfamax = dmin1(alfamax, 1.d0)

	alfa = dmin1(alfamax, 1.d0)


	if(alfamax.gt.1.d0) then

c	write(10, *)' The newtonian trial point is interior'

c  The newtonian trial point is interior

c  Checking interiority

	do i = 1, nfree
	ii = ifree(i)
	if(x(ii) + d(i).ge.u(ii).or.x(ii) + d(i).le. ele(ii)) then
	write(*, *)' Be careful. Possible rounding error in alfamax',
     *    alfamax
	stop
	endif
	end do





	pesca = 0.d0
	dnor2 = 0.d0
	gnor2 = 0.d0
	do i = 1, nfree
	ii = ifree(i)
	pesca = pesca + d(i) * g(ii)
	dnor2 = dnor2 + d(i)**2
	gnor2 = gnor2 + g(ii)**2
	end do


	if(pesca.ge.0.d0) then
	write(*, *)' Something wrong. Not a descent direction'
	stop
	endif


	cose = pesca/(dsqrt(gnor2)*dsqrt(dnor2))
	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' Cosine of angle newton-gradient:', cose
	endif

	if(cose.gt.-costol) then
	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
	write(10, *)' Search direction replaced by -gradient:'
	endif

c  Replace the scalar product for Armijo
	pesca = 0.d0
	do i = 1, nfree
	ii = ifree(i)
	d(i) = -g(ii)
	pesca = pesca - d(i)*d(i)
	end do
	dnor2 = gnor2
	endif

	dnorn = dsqrt(dnor2/dfloat(nfree))
c	write(10, *)' Norma de la direccion de busqueda:',dnorn

	xnorn = 0.d0
	do i = 1, nfree
	xnorn = xnorn + x(ifree(i))**2
	end do
	xnorn = dsqrt(xnorn/dfloat(nfree))


	do i = 1, nfree
	ii = ifree(i)
	aux(ii) = x(ii) + d(i)
	end do

	
	call funtan (m, n, aux, ambda, rho, h, fn,evalf,hrest)
	nef = nef + 1

c  Test Armijo
c  If Armijo does not hold, do backtracking (goto4)
	if(fn.gt.f + gamma * pesca) go to 4

c  Test beta-condition
	
	call gratan (m, n, aux, ambda, rho, h, aj, gaux,evalg,hrest,
     *  jacobh)
	neg = neg + 1
	pesnew = 0.d0
	do i = 1, nfree
	pesnew = pesnew + d(i) * gaux(ifree(i))
	end do

c  If the beta-condition does not hold, do extrapolation (goto3)
	if(pesnew.le.beta*pesca) go to 3
	do i = 1, nfree
	x(ifree(i)) = aux(ifree(i))
	end do
	f = fn
	do i = 1, n
	g(i) = gaux(i)
	end do
	kon = kon + 1
	npur = npur + 1
	go to 1
	

	endif
c  (This endif corresponds to      if(alfamax.gt.1) )

c  The point x + d is not interior


c	write(10, *)' The newtonian trial point is not interior'
c       write(10, *)' alfamax =', alfamax,' alfa =', alfa

	do i = 1, nfree
	ii = ifree(i)
	aux(ii) = x(ii) + alfamax * d(i)
	aux(ii) =
     *   dmin1(u(ii), dmax1(aux(ii), ele(ii)))
	end do


c	if(mod(kon,ipt).eq.0) 
c     *    write(10, *)' breakpoint aux:', (aux(i),i=1,n)

	call funtan (m, n, aux, ambda, rho, h, fn,evalf,hrest)

c	if(mod(kon,ipt).eq.0) 
c     *      write(10, *)' f(breakpoint)=', fn
c	nef = nef + 1

c   If the functional value at the boundary did not improve, do
c   backtracking (goto4)
c   Otherwise, do extrapolation (3)

c	write(10, *)' The trial point is not interior'

	dnor2 = 0.d0
	do i = 1, nfree
	dnor2 = dnorn + d(i)*d(i)
	end do
	dnorn = dsqrt (dnor2/dfloat(nfree))

c	write(10, *)' Norm of the direction:', dnorn
c	write(10, *)' dnorn antes de un goto 4'
c	write(10, *)' d ='
c	write(10, *) (d(i), i=1,nfree)
c	write(10, *)' dnorn =', dnorn
c	write(10, *)' pesca previously computed =', pesca

	pesca = 0.d0
	do i = 1, nfree
	pesca = pesca + g(ifree(i))*d(i)
	end do

c	write(10, *)' Verificando, pesca = ', pesca
c	write(10, *)' Current point:'
c	write(10, *) (x(i), i=1,n)
c	
c	write(10, *)' Verificando pesca de nuevo:'
c	pesca = 0.d0
c	do i = 1, n
c	pesca = pesca + g(i) * d(i)
c	end do
c	write(10, *)' Derivada direccional:', pesca
c
c	call funtan(m, n, x, ambda, rho, h, f)
c	call gratan (m, n, x, ambda, rho, h, aj, g)
c	write(10, *)' f(current point):', f
c	write(10, *)' Gradiente de current point:'
c	write(10, *) (g(i), i=1,n)
c
c	write(10, *)' Verificando pesca otra vez:'
c	pesca = 0.d0
c	do i = 1, n
c	pesca = pesca + g(i) * d(i)
c	end do
c	write(10, *)' Derivada direccional:', pesca
c
c	alftri = 1.d0
c	do itri = 1, 20
c	
c	write(10, *)
c	write(10, *)' itri = ', itri,'  alftri =', alftri
c	do i = 1, nfree
c	ii = ifree(i)
c	aux(ii) = x(ii) + alftri * d(i)
c	end do
c	write(10, *)' Trial calculado como en back:'
c	write(10, *) (aux(i), i=1,n)
c
c	do i = 1, n
c	aux(i) = x(i) + alftri * d(i)
c	end do
c
c	write(10, *)' Trial calculado en el verificador:'
c	write(10, *) (aux(i),i=1,n)
c
c	call funtan(m, n, aux, ambda, rho, h, ftrial)
c
c	write(10, *)' f =' , f, ' ftrial =', ftrial
c
c
c
c
c
c	alftri = alftri/10.d0
c	if(itri.eq.19) alftri = 7.1487099959547d-6
c	end do




c	if(fn.gt.f) write(10, *)' f(boundary)=', fn,' f(curr)=',f

	if(fn.gt.f) go to 4

c   Extrapolation
3	fbest = fn


	
	do i = 1, nfree
	ii = ifree(i)
	otro(ii) = aux(ii)
	end do



	if(alfa.lt.alfamax.and.2.d0*alfa.gt.alfamax) then

	alfa = alfamax
	else


	alfa = 2.d0 * alfa
	endif


	do i = 1, nfree
	ii = ifree(i)
	aux(ii) = x(ii) + alfa * d(i)
	aux(ii) = dmin1(u(ii), dmax1(ele(ii), aux(ii)))
	end do


	call funtan (m, n, aux, ambda, rho, h, fn,evalf,hrest)
	nef = nef + 1


c   If extrapolation is being successful, continue:
c	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
c
c	write(10, *)' fbest=',fbest,' fn=', fn,' alfa=', alfa
c	endif


	if(fn.lt.fbest) go to 3
c
c   Extrapolation is not successful anymore:


c	if(ipt.ge.0.and.mod(kon,ipt).eq.0) then
c	write(10, *)' Extrapolation not successful anymore'
c	endif


	do i = 1, nfree
	ii = ifree(i)
	x(ii) = otro(ii)
	end do


	f = fbest
	call gratan (m, n, x, ambda, rho, h, aj, g,evalg,hrest,jacobh)
	neg = neg + 1
	kon = kon + 1
	nextr = nextr + 1
	go to 1

c  Backtracking
4	alfnew = - pesca*alfa*alfa/(2.d0*(fn-f-pesca*alfa))


c          write(10, *)' alfa =', alfa,'  alfa new:', alfnew

	if(alfnew.gt.alfa/2.d0.or.alfnew.lt.0.1d0) alfnew = alfa/2.d0
	alfa = alfnew

c        write(10, *)' alfa new:', alfnew


	if(alfa*dnorn.le.distol*xnorn) then
	iflag = 2
	if(mod(kon,ipt).eq.0) then
	write(10, *)' Tango stopped by the relative diff. criterion'
	write(10, *)' alpha=', alfa,' dnorn=', dnorn
	write(10, *)' alpha*dnor=',alfa*dnorn,' xnorn=', xnorn
	endif
	return
	endif

	do i = 1, nfree
	ii = ifree(i)
	aux(ii) = x(ii) + alfa * d(i)
	end do
c	write(10, *)' Trial point:', (aux(i), i=1,n)

	call funtan (m, n, aux, ambda, rho, h, fn,evalf,hrest)

c	write(10, *)' f(x)=', f,'  f(trial point) =', fn
c	write(10, *)' pesca =', pesca,' alfa =', alfa
c	write(10, *)' Predicted reduction:', -pesca*alfa
c	write(10, *)' Actual reduction:', f - fn

	nef = nef + 1
c   Test Armijo
	   if(fn.gt.f + gamma*pesca*alfa) go to 4



c            Armijo holds
	   f = fn
	   do i = 1, nfree
	   ii = ifree(i)
	   x(ii) = aux(ii)
	   end do
	   call gratan (m, n, x, ambda, rho, h, aj, g,evalg,hrest,
     *     jacobh)
	   neg = neg + 1
	   kon = kon + 1
	   nback = nback + 1
	   go to 1
	end


	subroutine milalonga_cg (n, a, b, x, r, p, ap, nlin, ier, k, max)
	implicit double precision (a-h, o-z)
	dimension a(nlin, n), b(n), x(n), r(n), p(n), ap(n)
	ier = 0
	do i = 1, n
	x(i) = 0.d0
	r(i) = b(i)
	end do
	r2 = 0.d0

c  Here is the loop
	do k = 1, max
	r2a = r2
	r2 = 0.d0
	rnor = 0.d0
	do i = 1, n
	rnor = dmax1(rnor, dabs(r(i)))
	r2 = r2 + r(i)**2
	end do
	if(rnor.le.1.d-8) return
	beta = 0.d0
	if(k.gt.1) beta = r2/r2a
	if(k.eq.1) then
	do i = 1, n
	p(i) = r(i)
	end do
	else
	do i = 1, n
	p(i) = r(i) + beta * p(i)
	end do
	end if
	do i = 1, n
	ap(i) = 0.d0
	do j = 1, n
	ap(i) = ap(i) + a(i, j) * p(j)
	end do
	end do
	pap = 0.d0
	do i = 1, n
	pap = pap + p(i) * ap(i)
	end do
	if(pap.le.0.d0) then
	ier = 1
	return
	else
	alfa = r2/pap
	do i = 1, n
	x(i) = x(i) + alfa * p(i)
	r(i) = r(i) - alfa * ap(i)
	end do
	endif
	end do
	return
c  End of the loop
	end




	subroutine giveup(funtan, gratan, 
     *      n, x, f, g, ele, u, nef, neg, gamma, 
     *      aux, gaux, d, m, ambda, rho, h, aj,evalf,evalg,hrest,
     *      jacobh)
	implicit double precision (a-h,o-z)
	external evalf, evalg,hrest,jacobh
	dimension x(n), g(n), ele(n), u(n), aux(n), gaux(n), d(n)
	dimension ambda(m), h(m), aj(m, n)
	xnor = 0.d0
	do i = 1, n
	xnor = dmax1(xnor, dabs(x(i)))
	end do
	hh = dmax1(1.d-10, 1.d-5 * xnor)
	do i = 1, n
	aux(i) = x(i) - hh * g(i)
	aux(i) = dmax1(ele(i), dmin1(u(i), aux(i)))
	end do
        call gratan (m, n, aux, ambda, rho, h, aj, gaux,evalg,hrest,
     *  jacobh)
	neg = neg + 1
	ss = 0.d0
	sy = 0.d0
	do i = 1, n
	z = aux(i) - x(i)
	ss = ss + z * z
	sy = sy + z * (gaux(i) - g(i))
	end do
	if(sy.ne.0.d0) then
	step = dmax1(1.d-4, dmin1(1.d4, ss/sy))
	else
	step = 1.d4
	endif

	do i = 1, n
	aux(i) = dmin1(u(i), dmax1(ele(i), x(i)-step*g(i)))
	d(i) = aux(i) - x(i)
	end do
	alfa = 1.d0
	pesca = 0.d0
	do i = 1, n
	pesca = pesca + g(i) * d(i)
	end do

1	call funtan (m, n, aux, ambda, rho, h, fn,evalf,hrest)
	nef = nef + 1
	if(fn .gt. f + alfa * gamma * pesca) then
c  Armijo did not hold 
	alfnew = - pesca*alfa*alfa/(2.d0*(fn-f-pesca*alfa))
	if(alfnew.gt.alfa/2.d0.or.alfnew.lt.0.1d0) alfnew = alfa/2.d0
	alfa = alfnew
	do i = 1, n
	aux(i) = dmin1(u(i), dmax1(ele(i), x(i) + alfa*d(i)))
	end do
	go to 1
	else
c  Armijo holds. Return.
	do i = 1, n
	x(i) = aux(i)
	end do
	call gratan (m, n, x, ambda, rho, h, aj, g, evalg,hrest,jacobh)
	neg = neg + 1
	f = fn
	return
	endif
	end



	subroutine chole (n, a, ier, diag, nlin)
	implicit double precision (a-h,o-z)
	dimension a(nlin, n), diag(n)	
	ier = 0
c Save the diagonal of the matrix
	do i = 1, n
	diag(i) = a(i, i)
	end do
c Test nonnegativity of diagonal
	do i = 1, n
	if(diag(i).le.0) then
	ier = 1
	return
	endif
	end do

	a(1,1) = dsqrt(a(1, 1))
	if(n.eq.1)return

	do 1 i = 2, n
	do 2 j = 1 ,i-1
	z = 0.d0
	if(j.gt.1)then
	do 3 k=1,j-1
3	z = z + a(i,k) * a(j,k)
	endif
	a(i,j) = (a(i,j) - z)/a(j,j)
2	continue
	z = 0.d0
	do 4 j=1,i-1
4	z = z + a(i,j)**2
	temp = a(i, i) - z

c   Test positive definiteness
	if(temp.le.0.d0) then
	ier = i
c   Restore the diagonal
	do ii = 1, n
	a(ii, ii) = diag(ii)
	end do
c   Restore lower triangular part
	do ii = 2, n
	do j = 1, ii-1
	a(ii, j) = a(j, ii)
	end do
	end do	
	return
	endif

	a(i,i) = dsqrt(temp)
1	continue
	return
	end


	subroutine sicho (n, a, x, b, aux, nlin)
	implicit double precision (a-h,o-z)
	dimension a(nlin, n),x(n),b(n),aux(n)
	aux(1) = b(1)/a(1,1)
	if(n.gt.1)then
	do 1 i=2,n
	z = 0.d0
	do 2 j=1,i-1
2	z = z + a(i,j)*aux(j)
	aux(i) = (b(i) - z) / a(i,i)
1	continue
	endif
	x(n) = aux(n)/a(n,n)
	if(n.eq.1)return
	do 3 i=n-1,1,-1
	z = 0.d0
	do 4 j=i+1,n
4	z = z + a(j,i)*x(j)
	x(i) = (aux(i) - z)/a(i,i)
3	continue
	return
	end



	subroutine funtan (m, n, x, ambda, rho, h, f,evalf,hrest)
	implicit double precision (a-h, o-z)
	dimension x(n), ambda(m), h(m)
        external evalf,hrest
        
	call evalf (n, x, f)

c	write(10, *) ' f inside funtan:', f
c	write(10, *) ' m =', m
c	write(10, *) ' rho inside funtan:', rho

	
	if(m.eq.0) return
	rho2 = rho/2.d0


	call hrest (m, n, x, h)

c	write(10, *)' h inside funtan:'
c	write(10, *) (h(i),i=1,m)

	do i = 1, m
	f = f + (ambda(i) + rho2 * h(i)) * h(i)
	end do
	
	return
	end


	subroutine sumsq (m, n, x, ambda, rho, h, f,evalf,hrest)
	implicit double precision (a-h, o-z)
	dimension x(n), ambda(m), h(m)
        external evalf,hrest

	call hrest (m, n, x, h)

	f = 0.d0
	do i = 1, m
	f = f + h(i)* h(i)
	end do
	f = f/2.d0
	
	return
	end




	subroutine gratan (m, n, x, ambda, rho, h, aj, g, evalg,hrest,
     *  jacobh)
	implicit double precision (a-h, o-z)
	dimension x(n), ambda(m), h(m), aj(m, n), g(n)
	external evalg,hrest,jacobh
	
	call evalg(n, x, g)

c	write(10, *)' Dentro de gratan, lambda='
c	write(10, *)(ambda(i),i=1,m)

	if(m.eq.0) return

	
	call hrest (m, n, x, h)
	call jacobh (m, n, x, aj)

	do j = 1, n

	do i = 1, m
	g(j) = g(j) + ambda(i) * aj(i, j)
	end do

	z = 0.d0
	do i = 1, m
	z = z + aj(i, j) * h(i)
	end do

	g(j) = g(j) + rho * z
	end do
	return
	end



	subroutine grasum (m, n, x, ambda, rho, h, aj, g, evalg,hrest,
     *  jacobh)
	implicit double precision (a-h, o-z)
	dimension x(n), ambda(m), h(m), aj(m, n), g(n)
        external evalg,hrest,jacobh
	
	call hrest (m, n, x, h)
	call jacobh (m, n, x, aj)

	do j = 1, n
	g(j) = 0.d0
	do i = 1, m
	g(j) = g(j) + aj(i, j) * h(i)
	end do
	end do

	return
	end



	subroutine funquad (n, q, x, c, f, v, nlin)
	implicit double precision (a-h,o-z)
	dimension q(nlin, n), x(n), c(n), v(n)
	do i = 1, n
	v(i) =0.d0
	do j = 1, n
	v(i) = v(i) + q(i, j) * x(j)
	end do
	end do
	f = 0.d0
	do i = 1, n
	f = f + c(i)*x(i)
	end do
	do i = 1, n
	f = f + v(i)*x(i)
	end do
	return
	end


	subroutine graquad(n, x, q, c, g, nlin)
	implicit double precision (a-h, o-z)
	dimension x(n), q(nlin, n), c(n), g(n)
	do i = 1, n
	g(i) =0.d0
	do j = 1, n
	g(i) = g(i) + q(i, j) * x(j)
	end do
	end do
	do i = 1, n
	g(i) = 2.d0 * g(i) + c(i)
	end do
	return
	end	






		























































