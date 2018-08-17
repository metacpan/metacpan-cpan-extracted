c     this file contains the lbfgs algorithm and supporting routines
c     ****************
c     lbfgs subroutine
c     ****************
c     vanuxem gregory (2003): modified outputting information and iflag
c			      returned
c
      subroutine lbfgs(n,m,x,f,g,diagco,diag,iprint,maxit,eps,xtol,
     *grtol,w,iflag)
c
      integer n,m,iprint(2),iflag, maxit
      double precision x(n),g(n),diag(n),w(n*(2*m+1)+2*m)
      double precision f,eps,xtol,grtol
      logical diagco
c
c        limited memory bfgs method for large scale optimization
c                          jorge nocedal
c                        *** july 1990 ***
c
c 
c     this subroutine solves the unconstrained minimization problem
c 
c                      min f(x),    x= (x1,x2,...,xn),
c
c      using the limited memory bfgs method. the routine is especially
c      effective on problems involving a large number of variables. in
c      a typical iteration of this method an approximation hk to the
c      inverse of the hessian is obtained by applying m bfgs updates to
c      a diagonal matrix hk0, using information from the previous m steps.
c      the user specifies the number m, which determines the amount of
c      storage required by the routine. the user may also provide the
c      diagonal matrices hk0 if not satisfied with the default choice.
c      the algorithm is described in "on the limited memory bfgs method
c      for large scale optimization", by d. liu and j. nocedal,
c      mathematical programming b 45 (1989) 503-528.
c 
c      the user is required to calculate the function value f and its
c      gradient g. in order to allow the user complete control over
c      these computations, reverse  communication is used. the routine
c      must be called repeatedly under the control of the parameter
c      iflag. 
c
c      the steplength is determined at each iteration by means of the
c      line search routine mcvsrch, which is a slight modification of
c      the routine csrch written by more' and thuente.
c 
c      the calling statement is 
c 
c          call lbfgs(n,m,x,f,g,diagco,diag,iprint,eps,xtol,w,iflag)
c 
c      where
c 
c     n       is an integer variable that must be set by the user to the
c             number of variables. it is not altered by the routine.
c             restriction: n>0.
c 
c     m       is an integer variable that must be set by the user to
c             the number of corrections used in the bfgs update. it
c             is not altered by the routine. values of m less than 3 are
c             not recommended; large values of m will result in excessive
c             computing time. 3<= m <=7 is recommended. restriction: m>0.
c 
c     x       is a double precision array of length n. on initial entry
c             it must be set by the user to the values of the initial
c             estimate of the solution vector. on exit with iflag=0, it
c             contains the values of the variables at the best point
c             found (usually a solution).
c 
c     f       is a double precision variable. before initial entry and on
c             a re-entry with iflag=1, it must be set by the user to
c             contain the value of the function f at the point x.
c 
c     g       is a double precision array of length n. before initial
c             entry and on a re-entry with iflag=1, it must be set by
c             the user to contain the components of the gradient g at
c             the point x.
c 
c     diagco  is a logical variable that must be set to .true. if the
c             user  wishes to provide the diagonal matrix hk0 at each
c             iteration. otherwise it should be set to .false., in which
c             case  lbfgs will use a default value described below. if
c             diagco is set to .true. the routine will return at each
c             iteration of the algorithm with iflag=2, and the diagonal
c              matrix hk0  must be provided in the array diag.
c 
c 
c     diag    is a double precision array of length n. if diagco=.true.,
c             then on initial entry or on re-entry with iflag=2, diag
c             it must be set by the user to contain the values of the 
c             diagonal matrix hk0.  restriction: all elements of diag
c             must be positive.
c 
c     iprint  is an integer array of length two which must be set by the
c             user.
c 
c             iprint(1) specifies the frequency of the output:
c                iprint(1) < 0 : no output is generated,
c                iprint(1) = 0 : output only at first and last iteration,
c                iprint(1) > 0 : output every iprint(1) iterations.
c 
c             iprint(2) specifies the type of output generated:
c                iprint(2) = 0 : iteration count, number of function 
c                                evaluations, function value, norm of the
c                                gradient, and steplength,
c                iprint(2) = 1 : same as iprint(2)=0, plus vector of
c                                variables and  gradient vector at the
c                                initial point,
c                iprint(2) = 2 : same as iprint(2)=1, plus vector of
c                                variables,
c                iprint(2) = 3 : same as iprint(2)=2, plus gradient vector.
c 
c 
c     eps     is a positive double precision variable that must be set by
c             the user, and determines the accuracy with which the solution
c             is to be found. the subroutine terminates when
c
c                         ||g|| < eps max(1,||x||),
c
c             where ||.|| denotes the euclidean norm.
c 
c     xtol    is a  positive double precision variable that must be set by
c             the user to an estimate of the machine precision (e.g.
c             10**(-16) on a sun station 3/60). the line search routine will
c             terminate if the relative width of the interval of uncertainty
c             is less than xtol.
c 
c     w       is a double precision array of length n(2m+1)+2m used as
c             workspace for lbfgs. this array must not be altered by the
c             user.
c 
c     iflag   is an integer variable that must be set to 0 on initial entry
c             to the subroutine. a return with iflag < 0 or iflag > 2 indicates 
c	      an error, and iflag=0 indicates that the routine has terminated
c	      without detecting errors. on a return with iflag=1, the user must
c             evaluate the function f and gradient g. on a return with
c             iflag=2, the user must provide the diagonal matrix hk0.
c 
c             The following values of iflag, detecting an error,
c             are possible:
c 
c              iflag=-1  the i-th diagonal element of the diagonal inverse
c                        hessian approximation, given in diag, is not
c                        positive.
c           
c              iflag=-2  improper input parameters for lbfgs (n or m are
c                        not positive).
c
c             if  iflag > 2 the line search routine mcsrch failed:
c
c                       iflag = 3  more than 20 function evaluations were
c                                 required at the present iteration.
c
c                       iflag = 4  the step is too small.
c
c                       iflag = 5  the step is too large.
c
c                       iflag = 6  rounding errors prevent further progress. 
c                                 there may not be a step which satisfies
c                                 the sufficient decrease and curvature
c                                 conditions. tolerances may be too small.
c
c                       iflag = 7  relative width of the interval of
c                                 uncertainty is at most xtol.
c
c                       iflag = 8  improper input parameters.
c 
c 
c
c
c    on the driver:
c
c    the program that calls lbfgs must contain the declaration:
c
c                       external lb2
c
c    lb2 is a block data that defines the default values of several
c    parameters described in the common section. 
c
c 
c 
c    common:
c 
c     the subroutine contains one common area, which the user may wish to
c    reference:
c 
         common /lb3/mp,lp,gtol,stpmin,stpmax
c 
c    mp  is an integer variable with default value 6. it is used as the
c        unit number for the printing of the monitoring information
c        controlled by iprint.
c 
c    lp  is an integer variable with default value 6. it is used as the
c        unit number for the printing of error messages. this printing
c        may be suppressed by setting lp to a non-positive value.
c 
c    gtol is a double precision variable with default value 0.9, which
c        controls the accuracy of the line search routine mcsrch. if the
c        function and gradient evaluations are inexpensive with respect
c        to the cost of the iteration (which is sometimes the case when
c        solving very large problems) it may be advantageous to set gtol
c        to a small value. a typical small value is 0.1.  restriction:
c        gtol should be greater than 1.d-04.
c 
c    stpmin and stpmax are non-negative double precision variables which
c        specify lower and uper bounds for the step in the line search.
c        their default values are 1.d-20 and 1.d+20, respectively. these
c        values need not be modified unless the exponents are too large
c        for the machine being used, or unless the problem is extremely
c        badly scaled (in which case the exponents should be increased).
c 
c
c  machine dependencies
c
c        the only variables that are machine-dependent are xtol,
c        stpmin and stpmax.
c 
c
c  general information
c 
c    other routines called directly:  daxpy, ddot, lb1, mcsrch
c 
c    input/output  :  no input; diagnostic messages on unit mp and
c                     error messages on unit lp.
c 
c 
c     - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
c
      double precision gtol,one,zero,gnorm,ddot,stp1,ftol,stpmin,
     .                 stpmax,stp,ys,yy,sq,yr,beta,xnorm
      integer mp,lp,iter,nfun,point,ispt,iypt,maxfev,info,
     .        bound,npt,cp,i,nfev,inmc,iycn,iscn,request
      logical finish
c
      save
      data one,zero/1.0d+0,0.0d+0/
c
c     initialize
c     ----------
c
      if (grtol .gt. 1.d-04) gtol = grtol 
      request = 0
      if(iflag.eq.0) go to 10
      go to (172,100) iflag
  10  iter= 0
      if(n.le.0.or.m.le.0) go to 196
      if(gtol.le.1.d-04) then
        if(lp.gt.0 .and. iprint(1).ge.0) write(lp,245)
        gtol=9.d-01
      endif
      nfun= 1
      point= 0
      finish= .false.
      if(diagco) then
         do 30 i=1,n
 30      if (diag(i).le.zero) go to 195
      else
         do 40 i=1,n
 40      diag(i)= 1.0d0
      endif
c
c     the work vector w is divided as follows:
c     ---------------------------------------
c     the first n locations are used to store the gradient and
c         other temporary information.
c     locations (n+1)...(n+m) store the scalars rho.
c     locations (n+m+1)...(n+2m) store the numbers alpha used
c         in the formula that computes h*g.
c     locations (n+2m+1)...(n+2m+nm) store the last m search
c         steps.
c     locations (n+2m+nm+1)...(n+2m+2nm) store the last m
c         gradient differences.
c
c     the search steps and gradient differences are stored in a
c     circular order controlled by the parameter point.
c
      ispt= n+2*m
      iypt= ispt+n*m     
      do 50 i=1,n
 50   w(ispt+i)= -g(i)*diag(i)
      gnorm= dsqrt(ddot(n,g,1,g,1))
      stp1= one/gnorm
c
c     parameters for line search routine
c     
      ftol= 1.0d-4
      maxfev= 20
c
      if(iprint(1).ge.0) call lb1(iprint,iter,nfun,
     *                     gnorm,n,m,x,f,g,stp,finish,request)
c
c    --------------------
c     main iteration loop
c    --------------------
c
 80   iter= iter+1
      info=0
      bound=iter-1
      if(iter.eq.1) go to 165
      if (iter .gt. m)bound=m
c
         ys= ddot(n,w(iypt+npt+1),1,w(ispt+npt+1),1)
      if(.not.diagco) then
         yy= ddot(n,w(iypt+npt+1),1,w(iypt+npt+1),1)
         do 90 i=1,n
   90    diag(i)= ys/yy
      else
         iflag=2
         return
      endif
 100  continue
      if(diagco) then
        do 110 i=1,n
 110    if (diag(i).le.zero) go to 195
      endif
c
c     compute -h*g using the formula given in: nocedal, j. 1980,
c     "updating quasi-newton matrices with limited storage",
c     mathematics of computation, vol.24, no.151, pp. 773-782.
c     ---------------------------------------------------------
c
      cp= point
      if (point.eq.0) cp=m
      w(n+cp)= one/ys
      do 112 i=1,n
 112  w(i)= -g(i)
      cp= point
      do 125 i= 1,bound
         cp=cp-1
         if (cp.eq. -1)cp=m-1
         sq= ddot(n,w(ispt+cp*n+1),1,w,1)
         inmc=n+m+cp+1
         iycn=iypt+cp*n
         w(inmc)= w(n+cp+1)*sq
         call daxpy(n,-w(inmc),w(iycn+1),1,w,1)
 125  continue
c
      do 130 i=1,n
 130  w(i)=diag(i)*w(i)
c
      do 145 i=1,bound
         yr= ddot(n,w(iypt+cp*n+1),1,w,1)
         beta= w(n+cp+1)*yr
         inmc=n+m+cp+1
         beta= w(inmc)-beta
         iscn=ispt+cp*n
         call daxpy(n,beta,w(iscn+1),1,w,1)
         cp=cp+1
         if (cp.eq.m)cp=0
 145  continue
c
c     store the new search direction
c     ------------------------------
c
       do 160 i=1,n
 160   w(ispt+point*n+i)= w(i)
c
c     obtain the one-dimensional minimizer of the function 
c     by using the line search routine mcsrch
c     ----------------------------------------------------
 165  nfev=0
      stp=one
      if (iter.eq.1) stp=stp1
      do 170 i=1,n
 170  w(i)=g(i)
 172  continue
      call mcsrch(n,x,f,g,w(ispt+point*n+1),stp,ftol,
     *            xtol,maxfev,info,nfev,diag)
      if (info .eq. -1) then
        iflag=1
        return
      endif
      nfun= nfun + nfev
      if (info .ne. 1) then 
      	finish=.true.
      	request=2
        go to 180
      endif

c
c     compute the new step and gradient change 
c     -----------------------------------------
c
      npt=point*n
      do 175 i=1,n
      w(ispt+npt+i)= stp*w(ispt+npt+i)
 175  w(iypt+npt+i)= g(i)-w(i)
      point=point+1
      if (point.eq.m)point=0
c
c     termination test
c     ----------------
c
 180  gnorm= dsqrt(ddot(n,g,1,g,1))
      xnorm= dsqrt(ddot(n,x,1,x,1))
      xnorm= dmax1(1.0d0,xnorm)
      if (gnorm/xnorm .le. eps) finish=.true.
      if (iter .eq. maxit) then
      	finish=.true.
      	if (request .ne. 2) request=1
      endif
c
      if(iprint(1).ge.0) call lb1(iprint,iter,nfun,
     *               gnorm,n,m,x,f,g,stp,finish,request)
      if (finish) then
 	 maxit = iter
         if (request .gt. 0) then
	 	if (request .eq. 1) then
		 	iflag=3
	 	else 
	 		iflag = info
		 	if (info .eq. 0) iflag = 8
		 	if (info .eq. 2) iflag = 7
	 		go to 190
	 	endif
	 else
	 	iflag=0
 	 endif
         return
      endif
      go to 80
c
c     ------------------------------------------------------------
c     end of main iteration loop. error exits.
c     ------------------------------------------------------------
c
 190  if(lp.gt.0) then
	if (info .eq. 0) write (lp,200) 
	if (info .eq. 2 .and. iprint(1).ge.0) write (lp,202) xtol
	if (info .eq. 3 .and. iprint(1).ge.0) write (lp,203)
	if (info .eq. 4 .and. iprint(1).ge.0) write (lp,204) stpmin
	if (info .eq. 5 .and. iprint(1).ge.0) write (lp,205) stpmax
	if (info .eq. 6 .and. iprint(1).ge.0) write (lp,206)
      endif
      return
 195  iflag=-2
      if(lp.gt.0) write(lp,235) i
      return
 196  iflag= -3
      if(lp.gt.0) write(lp,240)

 200  format(/' Improper imput parameter for line search.')
 202  format(/' Relative width of the interval of uncertainty',/,
     .       ' is at most: ', d10.3)
 203  format (/,
     +' Line search cannot locate an adequate point after 20 function',/
     +,' and gradient evaluations.',/,
     +' Possible causes: 1 error in function or gradient evaluation;',/,
     +'                  2 rounding error dominate computation.')
 204  format(/' The step is at the lower bound:', d10.3)
 205  format(/' The step is at the upper bound:', d10.3)
 206  format (/,
     .' Rounding errors prevent further progress.',/
     .,'  There may not be a step which satisfies the',/,
     .' sufficient decrease and curvature conditions.',/,
     .' Tolerances may be too small.')
 235  format(/' iflag= -2',/' the',i5,'-th diagonal element of the',/
     .       ' inverse hessian approximation is not positive')
 240  format(/' iflag= -3',/' improper input parameters (n or m',
     .       ' are not positive)')
 245  format(/'  gtol is less than or equal to 1.d-04',
     .       / ' it has been reset to 9.d-01')
      return
      end
c
c     last line of subroutine lbfgs
c
c
      subroutine lb1(iprint,iter,nfun,
     *                     gnorm,n,m,x,f,g,stp,finish,request)
c
c     -------------------------------------------------------------
c     this routine prints monitoring information. the frequency and
c     amount of output are controlled by iprint.
c     -------------------------------------------------------------
c
      integer iprint(2),iter,nfun,lp,mp,n,m,request
      double precision x(n),g(n),f,gnorm,stp,gtol,stpmin,stpmax
      logical finish
      common /lb3/mp,lp,gtol,stpmin,stpmax
c
      if (iter.eq.0)then
           write(mp,10)
           write(mp,20) n,m
           write(mp,30)f,gnorm
                 if (iprint(2).ge.1)then
                     write(mp,40)
                     write(mp,50) (x(i),i=1,n)
                     write(mp,60)
                     write(mp,50) (g(i),i=1,n)
                  endif
           write(mp,10)
           write(mp,70)
      else
          if ((iprint(1).eq.0).and.(iter.ne.1.and..not.finish))return
              if (iprint(1).ne.0)then
                   if(mod(iter-1,iprint(1)).eq.0.or.finish)then
                         if(iprint(2).gt.1.and.iter.gt.1) write(mp,70)
                         write(mp,80)iter,nfun,f,gnorm,stp
                   else
                         return
                   endif
              else
                   if( iprint(2).gt.1.and.finish) write(mp,70)
                   write(mp,80)iter,nfun,f,gnorm,stp
              endif
              if (iprint(2).eq.2.or.iprint(2).eq.3)then
                    if (finish)then
                        write(mp,90)
                    else
                        write(mp,40)
                    endif
                      write(mp,50)(x(i),i=1,n)
                  if (iprint(2).eq.3)then
                      write(mp,60)
                      write(mp,50)(g(i),i=1,n)
                  endif
              endif
            if (finish) then
	    	if (request .gt. 0)then
		    if(request .eq. 1 ) write(mp,110)
		    if(request .eq. 2 ) write(mp,120)
		else
		    write(mp,100)
		endif
	    endif
      endif
c
 10   format('*************************************************')
 20   format('  n=',i5,'   number of corrections=',i2,
     .       /,  '       initial values')
 30   format(' f= ',1pd10.3,'   gnorm= ',1pd10.3)
 40   format(' vector x= ')
 50   format(6(2x,1pd10.3))
 60   format(' gradient vector g= ')
 70   format(/'   i   nfn',4x,'func',8x,'gnorm',7x,'steplength'/)
 80   format(2(i4,1x),3x,3(1pd10.3,2x))
 90   format(' final point x= ')
 100  format(/' The minimization terminated without detecting errors.',
     .       /' iflag = 0')
 110  format(/' The minimization reach the maximum number of',
     .      ' iteration.')
 120  format(/' Line search failed. Lowest point returned.')

      return
      end
c     ******
c
c
c   ----------------------------------------------------------
c     data 
c   ----------------------------------------------------------
c
      block data lb2
      integer lp,mp
      double precision gtol,stpmin,stpmax
      common /lb3/mp,lp,gtol,stpmin,stpmax
      data mp,lp,gtol,stpmin,stpmax/6,6,9.0d-01,1.0d-20,1.0d+20/
      end
c
c
c   ----------------------------------------------------------
c
c greg : removed daxpy,ddot
c
c    ------------------------------------------------------------------
c
c     **************************
c     line search routine mcsrch
c     **************************
c
      subroutine mcsrch(n,x,f,g,s,stp,ftol,xtol,maxfev,info,nfev,wa)
      integer n,maxfev,info,nfev
      double precision f,stp,ftol,gtol,xtol,stpmin,stpmax
      double precision x(n),g(n),s(n),wa(n)
      common /lb3/mp,lp,gtol,stpmin,stpmax
      save
c
c                     subroutine mcsrch
c                
c     a slight modification of the subroutine csrch of more' and thuente.
c     the changes are to allow reverse communication, and do not affect
c     the performance of the routine. 
c
c     the purpose of mcsrch is to find a step which satisfies
c     a sufficient decrease condition and a curvature condition.
c
c     at each stage the subroutine updates an interval of
c     uncertainty with endpoints stx and sty. the interval of
c     uncertainty is initially chosen so that it contains a
c     minimizer of the modified function
c
c          f(x+stp*s) - f(x) - ftol*stp*(gradf(x)'s).
c
c     if a step is obtained for which the modified function
c     has a nonpositive function value and nonnegative derivative,
c     then the interval of uncertainty is chosen so that it
c     contains a minimizer of f(x+stp*s).
c
c     the algorithm is designed to find a step which satisfies
c     the sufficient decrease condition
c
c           f(x+stp*s) .le. f(x) + ftol*stp*(gradf(x)'s),
c
c     and the curvature condition
c
c           abs(gradf(x+stp*s)'s)) .le. gtol*abs(gradf(x)'s).
c
c     if ftol is less than gtol and if, for example, the function
c     is bounded below, then there is always a step which satisfies
c     both conditions. if no step can be found which satisfies both
c     conditions, then the algorithm usually stops when rounding
c     errors prevent further progress. in this case stp only
c     satisfies the sufficient decrease condition.
c
c     the subroutine statement is
c
c        subroutine mcsrch(n,x,f,g,s,stp,ftol,xtol, maxfev,info,nfev,wa)
c     where
c
c       n is a positive integer input variable set to the number
c         of variables.
c
c       x is an array of length n. on input it must contain the
c         base point for the line search. on output it contains
c         x + stp*s.
c
c       f is a variable. on input it must contain the value of f
c         at x. on output it contains the value of f at x + stp*s.
c
c       g is an array of length n. on input it must contain the
c         gradient of f at x. on output it contains the gradient
c         of f at x + stp*s.
c
c       s is an input array of length n which specifies the
c         search direction.
c
c       stp is a nonnegative variable. on input stp contains an
c         initial estimate of a satisfactory step. on output
c         stp contains the final estimate.
c
c       ftol and gtol are nonnegative input variables. (in this reverse
c         communication implementation gtol is defined in a common
c         statement.) termination occurs when the sufficient decrease
c         condition and the directional derivative condition are
c         satisfied.
c
c       xtol is a nonnegative input variable. termination occurs
c         when the relative width of the interval of uncertainty
c         is at most xtol.
c
c       stpmin and stpmax are nonnegative input variables which
c         specify lower and upper bounds for the step. (in this reverse
c         communication implementatin they are defined in a common
c         statement).
c
c       maxfev is a positive integer input variable. termination
c         occurs when the number of calls to fcn is at least
c         maxfev by the end of an iteration.
c
c       info is an integer output variable set as follows:
c
c         info = 0  improper input parameters.
c
c         info =-1  a return is made to compute the function and gradient.
c
c         info = 1  the sufficient decrease condition and the
c                   directional derivative condition hold.
c
c         info = 2  relative width of the interval of uncertainty
c                   is at most xtol.
c
c         info = 3  number of calls to fcn has reached maxfev.
c
c         info = 4  the step is at the lower bound stpmin.
c
c         info = 5  the step is at the upper bound stpmax.
c
c         info = 6  rounding errors prevent further progress.
c                   there may not be a step which satisfies the
c                   sufficient decrease and curvature conditions.
c                   tolerances may be too small.
c
c       nfev is an integer output variable set to the number of
c         calls to fcn.
c
c       wa is a work array of length n.
c
c     subprograms called
c
c       mcstep
c
c       fortran-supplied...abs,max,min
c
c     argonne national laboratory. minpack project. june 1983
c     jorge j. more', david j. thuente
c
c     **********
      integer infoc,j
      logical brackt,stage1
      double precision dg,dgm,dginit,dgtest,dgx,dgxm,dgy,dgym,
     *       finit,ftest1,fm,fx,fxm,fy,fym,p5,p66,stx,sty,
     *       stmin,stmax,width,width1,xtrapf,zero
      data p5,p66,xtrapf,zero /0.5d0,0.66d0,4.0d0,0.0d0/
      if(info.eq.-1) go to 45
      infoc = 1
c
c     check the input parameters for errors.
c
      if (n .le. 0 .or. stp .le. zero .or. ftol .lt. zero .or.
     *    gtol .lt. zero .or. xtol .lt. zero .or. stpmin .lt. zero
     *    .or. stpmax .lt. stpmin .or. maxfev .le. 0) return
c
c     compute the initial gradient in the search direction
c     and check that s is a descent direction.
c
      dginit = zero
      do 10 j = 1, n
         dginit = dginit + g(j)*s(j)
   10    continue
      if (dginit .ge. zero) then
         write(lp,15)
   15    format(/'  the search direction is not a descent direction')
         return
         endif
c
c     initialize local variables.
c
      brackt = .false.
      stage1 = .true.
      nfev = 0
      finit = f
      dgtest = ftol*dginit
      width = stpmax - stpmin
      width1 = width/p5
      do 20 j = 1, n
         wa(j) = x(j)
   20    continue
c
c     the variables stx, fx, dgx contain the values of the step,
c     function, and directional derivative at the best step.
c     the variables sty, fy, dgy contain the value of the step,
c     function, and derivative at the other endpoint of
c     the interval of uncertainty.
c     the variables stp, f, dg contain the values of the step,
c     function, and derivative at the current step.
c
      stx = zero
      fx = finit
      dgx = dginit
      sty = zero
      fy = finit
      dgy = dginit
c
c     start of iteration.
c
   30 continue
c
c        set the minimum and maximum steps to correspond
c        to the present interval of uncertainty.
c
         if (brackt) then
            stmin = min(stx,sty)
            stmax = max(stx,sty)
         else
            stmin = stx
            stmax = stp + xtrapf*(stp - stx)
            end if
c
c        force the step to be within the bounds stpmax and stpmin.
c
         stp = max(stp,stpmin)
         stp = min(stp,stpmax)
c
c        if an unusual termination is to occur then let
c        stp be the lowest point obtained so far.
c
         if ((brackt .and. (stp .le. stmin .or. stp .ge. stmax))
     *      .or. nfev .ge. maxfev-1 .or. infoc .eq. 0
     *      .or. (brackt .and. stmax-stmin .le. xtol*stmax)) stp = stx
c
c        evaluate the function and gradient at stp
c        and compute the directional derivative.
c        we return to main program to obtain f and g.
c
         do 40 j = 1, n
            x(j) = wa(j) + stp*s(j)
   40       continue
         info=-1
         return
c
   45    info=0
         nfev = nfev + 1
         dg = zero
         do 50 j = 1, n
            dg = dg + g(j)*s(j)
   50       continue
         ftest1 = finit + stp*dgtest
c
c        test for convergence.
c
         if ((brackt .and. (stp .le. stmin .or. stp .ge. stmax))
     *      .or. infoc .eq. 0) info = 6
         if (stp .eq. stpmax .and.
     *       f .le. ftest1 .and. dg .le. dgtest) info = 5
         if (stp .eq. stpmin .and.
     *       (f .gt. ftest1 .or. dg .ge. dgtest)) info = 4
         if (nfev .ge. maxfev) info = 3
         if (brackt .and. stmax-stmin .le. xtol*stmax) info = 2
         if (f .le. ftest1 .and. abs(dg) .le. gtol*(-dginit)) info = 1
c
c        check for termination.
c
         if (info .ne. 0) return
c
c        in the first stage we seek a step for which the modified
c        function has a nonpositive value and nonnegative derivative.
c
         if (stage1 .and. f .le. ftest1 .and.
     *       dg .ge. min(ftol,gtol)*dginit) stage1 = .false.
c
c        a modified function is used to predict the step only if
c        we have not obtained a step for which the modified
c        function has a nonpositive function value and nonnegative
c        derivative, and if a lower function value has been
c        obtained but the decrease is not sufficient.
c
         if (stage1 .and. f .le. fx .and. f .gt. ftest1) then
c
c           define the modified function and derivative values.
c
            fm = f - stp*dgtest
            fxm = fx - stx*dgtest
            fym = fy - sty*dgtest
            dgm = dg - dgtest
            dgxm = dgx - dgtest
            dgym = dgy - dgtest
c
c           call cstep to update the interval of uncertainty
c           and to compute the new step.
c
            call mcstep(stx,fxm,dgxm,sty,fym,dgym,stp,fm,dgm,
     *                 brackt,stmin,stmax,infoc)
c
c           reset the function and gradient values for f.
c
            fx = fxm + stx*dgtest
            fy = fym + sty*dgtest
            dgx = dgxm + dgtest
            dgy = dgym + dgtest
         else
c
c           call mcstep to update the interval of uncertainty
c           and to compute the new step.
c
            call mcstep(stx,fx,dgx,sty,fy,dgy,stp,f,dg,
     *                 brackt,stmin,stmax,infoc)
            end if
c
c        force a sufficient decrease in the size of the
c        interval of uncertainty.
c
         if (brackt) then
            if (abs(sty-stx) .ge. p66*width1)
     *         stp = stx + p5*(sty - stx)
            width1 = width
            width = abs(sty-stx)
            end if
c
c        end of iteration.
c
         go to 30
c
c     last line of subroutine mcsrch.
c
      end
      subroutine mcstep(stx,fx,dx,sty,fy,dy,stp,fp,dp,brackt,
     *                 stpmin,stpmax,info)
      integer info
      double precision stx,fx,dx,sty,fy,dy,stp,fp,dp,stpmin,stpmax
      logical brackt,bound
c
c     subroutine mcstep
c
c     the purpose of mcstep is to compute a safeguarded step for
c     a linesearch and to update an interval of uncertainty for
c     a minimizer of the function.
c
c     the parameter stx contains the step with the least function
c     value. the parameter stp contains the current step. it is
c     assumed that the derivative at stx is negative in the
c     direction of the step. if brackt is set true then a
c     minimizer has been bracketed in an interval of uncertainty
c     with endpoints stx and sty.
c
c     the subroutine statement is
c
c       subroutine mcstep(stx,fx,dx,sty,fy,dy,stp,fp,dp,brackt,
c                        stpmin,stpmax,info)
c
c     where
c
c       stx, fx, and dx are variables which specify the step,
c         the function, and the derivative at the best step obtained
c         so far. the derivative must be negative in the direction
c         of the step, that is, dx and stp-stx must have opposite
c         signs. on output these parameters are updated appropriately.
c
c       sty, fy, and dy are variables which specify the step,
c         the function, and the derivative at the other endpoint of
c         the interval of uncertainty. on output these parameters are
c         updated appropriately.
c
c       stp, fp, and dp are variables which specify the step,
c         the function, and the derivative at the current step.
c         if brackt is set true then on input stp must be
c         between stx and sty. on output stp is set to the new step.
c
c       brackt is a logical variable which specifies if a minimizer
c         has been bracketed. if the minimizer has not been bracketed
c         then on input brackt must be set false. if the minimizer
c         is bracketed then on output brackt is set true.
c
c       stpmin and stpmax are input variables which specify lower
c         and upper bounds for the step.
c
c       info is an integer output variable set as follows:
c         if info = 1,2,3,4,5, then the step has been computed
c         according to one of the five cases below. otherwise
c         info = 0, and this indicates improper input parameters.
c
c     subprograms called
c
c       fortran-supplied ... abs,max,min,sqrt
c
c     argonne national laboratory. minpack project. june 1983
c     jorge j. more', david j. thuente
c
      double precision gamma,p,q,r,s,sgnd,stpc,stpf,stpq,theta
      info = 0
c
c     check the input parameters for errors.
c
      if ((brackt .and. (stp .le. min(stx,sty) .or.
     *    stp .ge. max(stx,sty))) .or.
     *    dx*(stp-stx) .ge. 0.0 .or. stpmax .lt. stpmin) return
c
c     determine if the derivatives have opposite sign.
c
      sgnd = dp*(dx/abs(dx))
c
c     first case. a higher function value.
c     the minimum is bracketed. if the cubic step is closer
c     to stx than the quadratic step, the cubic step is taken,
c     else the average of the cubic and quadratic steps is taken.
c
      if (fp .gt. fx) then
         info = 1
         bound = .true.
         theta = 3*(fx - fp)/(stp - stx) + dx + dp
         s = max(abs(theta),abs(dx),abs(dp))
         gamma = s*sqrt((theta/s)**2 - (dx/s)*(dp/s))
         if (stp .lt. stx) gamma = -gamma
         p = (gamma - dx) + theta
         q = ((gamma - dx) + gamma) + dp
         r = p/q
         stpc = stx + r*(stp - stx)
         stpq = stx + ((dx/((fx-fp)/(stp-stx)+dx))/2)*(stp - stx)
         if (abs(stpc-stx) .lt. abs(stpq-stx)) then
            stpf = stpc
         else
           stpf = stpc + (stpq - stpc)/2
           end if
         brackt = .true.
c
c     second case. a lower function value and derivatives of
c     opposite sign. the minimum is bracketed. if the cubic
c     step is closer to stx than the quadratic (secant) step,
c     the cubic step is taken, else the quadratic step is taken.
c
      else if (sgnd .lt. 0.0) then
         info = 2
         bound = .false.
         theta = 3*(fx - fp)/(stp - stx) + dx + dp
         s = max(abs(theta),abs(dx),abs(dp))
         gamma = s*sqrt((theta/s)**2 - (dx/s)*(dp/s))
         if (stp .gt. stx) gamma = -gamma
         p = (gamma - dp) + theta
         q = ((gamma - dp) + gamma) + dx
         r = p/q
         stpc = stp + r*(stx - stp)
         stpq = stp + (dp/(dp-dx))*(stx - stp)
         if (abs(stpc-stp) .gt. abs(stpq-stp)) then
            stpf = stpc
         else
            stpf = stpq
            end if
         brackt = .true.
c
c     third case. a lower function value, derivatives of the
c     same sign, and the magnitude of the derivative decreases.
c     the cubic step is only used if the cubic tends to infinity
c     in the direction of the step or if the minimum of the cubic
c     is beyond stp. otherwise the cubic step is defined to be
c     either stpmin or stpmax. the quadratic (secant) step is also
c     computed and if the minimum is bracketed then the the step
c     closest to stx is taken, else the step farthest away is taken.
c
      else if (abs(dp) .lt. abs(dx)) then
         info = 3
         bound = .true.
         theta = 3*(fx - fp)/(stp - stx) + dx + dp
         s = max(abs(theta),abs(dx),abs(dp))
c
c        the case gamma = 0 only arises if the cubic does not tend
c        to infinity in the direction of the step.
c
         gamma = s*sqrt(max(0.0d0,(theta/s)**2 - (dx/s)*(dp/s)))
         if (stp .gt. stx) gamma = -gamma
         p = (gamma - dp) + theta
         q = (gamma + (dx - dp)) + gamma
         r = p/q
         if (r .lt. 0.0 .and. gamma .ne. 0.0) then
            stpc = stp + r*(stx - stp)
         else if (stp .gt. stx) then
            stpc = stpmax
         else
            stpc = stpmin
            end if
         stpq = stp + (dp/(dp-dx))*(stx - stp)
         if (brackt) then
            if (abs(stp-stpc) .lt. abs(stp-stpq)) then
               stpf = stpc
            else
               stpf = stpq
               end if
         else
            if (abs(stp-stpc) .gt. abs(stp-stpq)) then
               stpf = stpc
            else
               stpf = stpq
               end if
            end if
c
c     fourth case. a lower function value, derivatives of the
c     same sign, and the magnitude of the derivative does
c     not decrease. if the minimum is not bracketed, the step
c     is either stpmin or stpmax, else the cubic step is taken.
c
      else
         info = 4
         bound = .false.
         if (brackt) then
            theta = 3*(fp - fy)/(sty - stp) + dy + dp
            s = max(abs(theta),abs(dy),abs(dp))
            gamma = s*sqrt((theta/s)**2 - (dy/s)*(dp/s))
            if (stp .gt. sty) gamma = -gamma
            p = (gamma - dp) + theta
            q = ((gamma - dp) + gamma) + dy
            r = p/q
            stpc = stp + r*(sty - stp)
            stpf = stpc
         else if (stp .gt. stx) then
            stpf = stpmax
         else
            stpf = stpmin
            end if
         end if
c
c     update the interval of uncertainty. this update does not
c     depend on the new step or the case analysis above.
c
      if (fp .gt. fx) then
         sty = stp
         fy = fp
         dy = dp
      else
         if (sgnd .lt. 0.0) then
            sty = stx
            fy = fx
            dy = dx
            end if
         stx = stp
         fx = fp
         dx = dp
         end if
c
c     compute the new step and safeguard it.
c
      stpf = min(stpmax,stpf)
      stpf = max(stpmin,stpf)
      stp = stpf
      if (brackt .and. bound) then
         if (sty .gt. stx) then
            stp = min(stx+0.66*(sty-stx),stp)
         else
            stp = max(stx+0.66*(sty-stx),stp)
            end if
         end if
      return
c
c     last line of subroutine mcstep.
c
      end

