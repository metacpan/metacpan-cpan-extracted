      subroutine lmqn (ifail, n, x, f, g, w, lw, sfun,
     *            msglvl, maxit, maxfun, eta, stepmx, accrcy, xtol)
      implicit          double precision (a-h,o-z)
      integer           msglvl, n, maxfun, ifail, lw, ipivot(1)
      double precision  x(n), g(n), w(lw), eta, xtol, stepmx, f, accrcy

c
c this routine solves the optimization problem
c
c            minimize f(x)
c               x
c
c where x is a vector of n real variables.  the method used is
c a truncated-newton algorithm (see "newton-type minimization via
c the lanczos method" by s.g. nash (siam j. numer. anal. 21 (1984),
c pp. 770-778).  this algorithm finds a local minimum of f(x).  it does
c not assume that the function f is convex (and so cannot guarantee a
c global solution), but does assume that the function is bounded below.
c it can solve problems having any number of variables, but it is
c especially useful when the number of variables (n) is large.
c
c subroutine parameters:
c
c ierror - (integer) error code
c          ( 0 => normal return)
c          ( 2 => more than maxfun evaluations)
c          ( 3 => line search failed to find
c          (          lower point (may not be serious)
c          (-1 => error in input parameters)
c n      - (integer) number of variables
c x      - (real*8) vector of length at least n; on input, an initial
c          estimate of the solution; on output, the computed solution.
c g      - (real*8) vector of length at least n; on output, the final
c          value of the gradient
c f      - (real*8) on input, a rough estimate of the value of the
c          objective function at the solution; on output, the value
c          of the objective function at the solution
c w      - (real*8) work vector of length at least 14*n
c lw     - (integer) the declared dimension of w
c sfun   - a user-specified subroutine that computes the function
c          and gradient of the objective function.  it must have
c          the calling sequence
c             subroutine sfun (n, x, f, g)
c             integer           n
c             double precision  x(n), g(n), f
c
c eta    - severity of the linesearch
c maxfun - maximum allowable number of function evaluations
c xtol   - desired accuracy for the solution x*
c stepmx - maximum allowable step in the linesearch
c accrcy - accuracy of computed function values
c msglvl - determines quantity of printed output
c          0 = none, 1 = one line per major iteration.
c maxit  - maximum number of inner iterations per step

c
c this routine is a truncated-newton method.
c the truncated-newton method is preconditioned by a limited-memory
c quasi-newton method (this preconditioning strategy is developed
c in this routine) with a further diagonal scaling (see routine ndia3).
c for further details on the parameters, see routine tn.
c
      integer i, icycle, ioldg, ipk, iyk, loldg, lpk, lsr,
     *     lwtest, lyk, lyr, nftotl, niter, nm1, numf, nwhy
      double precision abstol, alpha, difnew, difold, epsmch,
     *     epsred, fkeep, fm, fnew, fold, fstop, ftest, gnorm, gsk,
     *     gtg, gtpnew, oldf, oldgtp, one, pe, peps, pnorm, reltol,
     *     rteps, rtleps, rtol, rtolsq, small, spe, tiny,
     *     tnytol, toleps, xnorm, yksk, yrsr, zero
      logical lreset, upd1
c
c the following imsl and standard functions are used
c
      double precision dabs, ddot, dsqrt, step1, dnrm2
      external sfun
      common /subscr/ lgv,lz1,lzk,lv,lsk,lyk,ldiagb,lsr,lyr,
     *     loldg,lhg,lhyk,lpk,lemat,lwtest
c
c initialize parameters and constants
c
      if (msglvl .ge. 1) write(*,800)
      call setpar(n)
      upd1 = .true.
      ireset = 0
      nfeval = 0
      nmodif = 0
      nlincg = 0
      fstop = f
      zero = 0.d0
      one = 1.d0
      nm1 = n - 1
c
c within this routine the array w(loldg) is shared by w(lhyr)
c
      lhyr = loldg
c
c check parameters and set constants
c
      call chkucp(lwtest,maxfun,nwhy,n,alpha,epsmch,
     *     eta,peps,rteps,rtol,rtolsq,stepmx,ftest,
     *     xtol,xnorm,x,lw,small,tiny,accrcy)
      if (nwhy .lt. 0) go to 120
      call setucr(small,nftotl,niter,n,f,fnew,
     *     fm,gtg,oldf,sfun,g,x)
      fold = fnew
      if (msglvl .ge. 1) write(*,810) niter,nftotl,nlincg,fnew,gtg
c
c check for small gradient at the starting point.
c
      ftest = one + dabs(fnew)
      if (gtg .lt. 1.d-4*epsmch*ftest*ftest) go to 90
c
c set initial values to other parameters
c
      icycle = nm1
      toleps = rtol + rteps
      rtleps = rtolsq + epsmch
      gnorm  = dsqrt(gtg)
      difnew = zero
      epsred = 5.0d-2
      fkeep  = fnew
c
c set the diagonal of the approximate hessian to unity.
c
      idiagb = ldiagb
      do 10 i = 1,n
         w(idiagb) = one
         idiagb = idiagb + 1
10    continue
c
c ..................start of main iterative loop..........
c
c compute the new search direction
c
      modet = msglvl - 3
      call modlnp(modet,w(lpk),w(lgv),w(lz1),w(lv),
     *     w(ldiagb),w(lemat),x,g,w(lzk),
     *     n,w,lw,niter,maxit,nfeval,nmodif,
     *     nlincg,upd1,yksk,gsk,yrsr,lreset,sfun,.false.,ipivot,
     *     accrcy,gtpnew,gnorm,xnorm)
20    continue
      call dcopy(n,g,1,w(loldg),1)
      pnorm = dnrm2(n,w(lpk),1)
      oldf = fnew
      oldgtp = gtpnew
c
c prepare to compute the step length
c
      pe = pnorm + epsmch
c
c compute the absolute and relative tolerances for the linear search
c
      reltol = rteps*(xnorm + one)/pe
      abstol = - epsmch*ftest/(oldgtp - epsmch)
c
c compute the smallest allowable spacing between points in
c the linear search
c
      tnytol = epsmch*(xnorm + one)/pe
      spe = stepmx/pe
c
c set the initial step length.
c
      alpha = step1(fnew,fm,oldgtp,spe)
c
c perform the linear search
c
      call linder(n,sfun,small,epsmch,reltol,abstol,tnytol,
     *     eta,zero,spe,w(lpk),oldgtp,x,fnew,alpha,g,numf,
     *     nwhy,w,lw)
c
      fold = fnew
      niter = niter + 1
      nftotl = nftotl + numf
      gtg = ddot(n,g,1,g,1)
      if (msglvl .ge. 1) write(*,810) niter,nftotl,nlincg,fnew,gtg
      if (nwhy .lt. 0) go to 120
      if (nwhy .eq. 0 .or. nwhy .eq. 2) go to 30
c
c the linear search has failed to find a lower point
c
      nwhy = 3
      go to 100
30    if (nwhy .le. 1) go to 40
      call sfun(n,x,fnew,g)
      nftotl = nftotl + 1
c
c terminate if more than maxfun evalutations have been made
c
40    nwhy = 2
      if (nftotl .gt. maxfun) go to 110
      nwhy = 0
c
c set up parameters used in convergence and resetting tests
c
      difold = difnew
      difnew = oldf - fnew
c
c if this is the first iteration of a new cycle, compute the
c percentage reduction factor for the resetting test.
c
      if (icycle .ne. 1) go to 50
      if (difnew .gt. 2.0d0 *difold) epsred = epsred + epsred
      if (difnew .lt. 5.0d-1*difold) epsred = 5.0d-1*epsred
50    continue
      gnorm = dsqrt(gtg)
      ftest = one + dabs(fnew)
      xnorm = dnrm2(n,x,1)
c
c test for convergence
c
      if ((alpha*pnorm .lt. toleps*(one + xnorm)
     *     .and. dabs(difnew) .lt. rtleps*ftest
     *     .and. gtg .lt. peps*ftest*ftest)
     *     .or. gtg .lt. 1.d-4*accrcy*ftest*ftest) go to 90
c
c compute the change in the iterates and the corresponding change
c in the gradients
c
      isk = lsk
      ipk = lpk
      iyk = lyk
      ioldg = loldg
      do 60 i = 1,n
         w(iyk) = g(i) - w(ioldg)
         w(isk) = alpha*w(ipk)
         ipk = ipk + 1
         isk = isk + 1
         iyk = iyk + 1
         ioldg = ioldg + 1
60    continue
c
c set up parameters used in updating the direction of search.
c
      yksk = ddot(n,w(lyk),1,w(lsk),1)
      lreset = .false.
      if (icycle .eq. nm1 .or. difnew .lt.
     *     epsred*(fkeep-fnew)) lreset = .true.
      if (lreset) go to 70
      yrsr = ddot(n,w(lyr),1,w(lsr),1)
      if (yrsr .le. zero) lreset = .true.
70    continue
      upd1 = .false.
c
c      compute the new search direction
c
      modet = msglvl - 3
      call modlnp(modet,w(lpk),w(lgv),w(lz1),w(lv),
     *     w(ldiagb),w(lemat),x,g,w(lzk),
     *     n,w,lw,niter,maxit,nfeval,nmodif,
     *     nlincg,upd1,yksk,gsk,yrsr,lreset,sfun,.false.,ipivot,
     *     accrcy,gtpnew,gnorm,xnorm)
      if (lreset) go to 80
c
c      store the accumulated change in the point and gradient as an
c      "average" direction for preconditioning.
c
      call dxpy(n,w(lsk),1,w(lsr),1)
      call dxpy(n,w(lyk),1,w(lyr),1)
      icycle = icycle + 1
      goto 20
c
c reset
c
80    ireset = ireset + 1
c
c initialize the sum of all the changes in x.
c
      call dcopy(n,w(lsk),1,w(lsr),1)
      call dcopy(n,w(lyk),1,w(lyr),1)
      fkeep = fnew
      icycle = 1
      go to 20
c
c ...............end of main iteration.......................
c
90    ifail = 0
      f = fnew
      go to 130
100   oldf = fnew
c
c local search here could be installed here
c
110    f = oldf
c
c set ifail
c
120   ifail = nwhy

130   if (msglvl .ge. 1 .and. ifail .lt. 0) then
	      if (ifail .ne. 0) write(*,820) ifail
	      return
      endif
      
      if (msglvl .ge. 1) then
	      if (ifail .ne. 0) write(*,820) ifail
	      write(*,830) f
	      write(*,840)
	      nmax = 10
	      if (n .lt. nmax) nmax = n
	      write(*,850) (i,x(i),i=1,nmax)
      endif
      return

800   format(//' nit   nf   cg', 9x, 'f', 21x, 'gtg',//)
810   format(' ',i3,1x,i4,1x,i4,1x,1pd22.15,2x,1pd15.8)
820   format(//,' error code =', i3)
830   format(//,' optimal function value = ', 1pd22.15)
840   format(10x, 'current solution is (at most 10 components)', /,
     *       14x, 'i', 11x, 'x(i)')
850   format(10x, i5, 2x, 1pd22.15)

      end
c
c
      subroutine lmqnbc (ifail, n, x, f, g, w, lw, sfun, low, up,
     *   ipivot, msglvl, maxit, maxfun, eta, stepmx, accrcy, xtol)
      implicit         double precision (a-h,o-z)
      integer          msglvl,n,maxfun,ifail,lw
      integer          ipivot(n)
      double precision eta,xtol,stepmx,f,accrcy
      double precision x(n),g(n),w(lw),low(n),up(n)

c this routine solves the optimization problem
c
c   minimize     f(x)
c      x
c   subject to   low <= x <= up
c
c where x is a vector of n real variables.  the method used is
c a truncated-newton algorithm (see "newton-type minimization via
c the lanczos algorithm" by s.g. nash (technical report 378, math.
c the lanczos method" by s.g. nash (siam j. numer. anal. 21 (1984),
c pp. 770-778).  this algorithm finds a local minimum of f(x).  it does
c not assume that the function f is convex (and so cannot guarantee a
c global solution), but does assume that the function is bounded below.
c it can solve problems having any number of variables, but it is
c especially useful when the number of variables (n) is large.
c
c subroutine parameters:
c
c ierror  - (integer) error code
c           ( 0 => normal return
c           ( 2 => more than maxfun evaluations
c           ( 3 => line search failed to find lower
c           (          point (may not be serious)
c           (-1 => error in input parameters
c n       - (integer) number of variables
c x       - (real*8) vector of length at least n; on input, an initial
c           estimate of the solution; on output, the computed solution.
c g       - (real*8) vector of length at least n; on output, the final
c           value of the gradient
c f       - (real*8) on input, a rough estimate of the value of the
c           objective function at the solution; on output, the value
c           of the objective function at the solution
c w       - (real*8) work vector of length at least 14*n
c lw      - (integer) the declared dimension of w
c sfun    - a user-specified subroutine that computes the function
c           and gradient of the objective function.  it must have
c           the calling sequence
c             subroutine sfun (n, x, f, g)
c             integer           n
c             double precision  x(n), g(n), f
c low, up - (real*8) vectors of length at least n containing
c           the lower and upper bounds on the variables.  if
c           there are no bounds on a particular variable, set
c           the bounds to -1.d38 and 1.d38, respectively.
c ipivot  - (integer) work vector of length at least n, used
c           to record which variables are at their bounds.
c
c eta    - severity of the linesearch
c maxfun - maximum allowable number of function evaluations
c xtol   - desired accuracy for the solution x*
c stepmx - maximum allowable step in the linesearch
c accrcy - accuracy of computed function values
c msglvl - controls quantity of printed output
c          0 = none, 1 = one line per major iteration.
c maxit  - maximum number of inner iterations per step
c
c this routine is a bounds-constrained truncated-newton method.
c the truncated-newton method is preconditioned by a limited-memory
c quasi-newton method (this preconditioning strategy is developed
c in this routine) with a further diagonal scaling (see routine ndia3).
c for further details on the parameters, see routine tnbc.
c
      integer i, icycle, ioldg, ipk, iyk, loldg, lpk, lsr,
     *     lwtest, lyk, lyr, nftotl, niter, nm1, numf, nwhy
      double precision abstol, alpha, difnew, difold, epsmch, epsred,
     *     fkeep, flast, fm, fnew, fold, fstop, ftest, gnorm, gsk,
     *     gtg, gtpnew, oldf, oldgtp, one, pe, peps, pnorm, reltol,
     *     rteps, rtleps, rtol, rtolsq, small, spe, tiny,
     *     tnytol, toleps, xnorm, yksk, yrsr, zero
      logical conv, lreset, upd1, newcon
c
c the following standard functions and system functions are used
c
      double precision dabs, ddot, dnrm2, dsqrt, step1
      external sfun
      common/subscr/ lgv, lz1, lzk, lv, lsk, lyk, ldiagb, lsr, lyr,
     *     loldg, lhg, lhyk, lpk, lemat, lwtest
c
c check that initial x is feasible and that the bounds are consistent
c
      call crash(n,x,ipivot,low,up,ier)
      if (ier .ne. 0) write(*,800)
      if (ier .ne. 0) return
      if (msglvl .ge. 1) write(*,810)
c
c initialize variables
c
      call setpar(n)
      upd1 = .true.
      ireset = 0
      nfeval = 0
      nmodif = 0
      nlincg = 0
      fstop = f
      conv = .false.
      zero = 0.d0
      one = 1.d0
      nm1 = n - 1
c
c within this routine the array w(loldg) is shared by w(lhyr)
c
      lhyr = loldg
c
c check parameters and set constants
c
      call chkucp(lwtest,maxfun,nwhy,n,alpha,epsmch,
     *     eta,peps,rteps,rtol,rtolsq,stepmx,ftest,
     *     xtol,xnorm,x,lw,small,tiny,accrcy)
      if (nwhy .lt. 0) go to 160
      call setucr(small,nftotl,niter,n,f,fnew,
     *     fm,gtg,oldf,sfun,g,x)
      fold = fnew
      flast = fnew
c
c test the lagrange multipliers to see if they are non-negative.
c because the constraints are only lower bounds, the components
c of the gradient corresponding to the active constraints are the
c lagrange multipliers.  afterwords, the projected gradient is formed.
c
      do 10 i = 1,n
         if (ipivot(i) .eq. 2) go to 10
         if (-ipivot(i)*g(i) .ge. 0.d0) go to 10
         ipivot(i) = 0
10    continue
      call ztime(n,g,ipivot)
      gtg = ddot(n,g,1,g,1)
      if (msglvl .ge. 1)
     *    call monit(n,x,fnew,g,niter,nftotl,nfeval,lreset,ipivot)
c
c check if the initial point is a local minimum.
c
      ftest = one + dabs(fnew)
      if (gtg .lt. 1.d-4*epsmch*ftest*ftest) go to 130
c
c set initial values to other parameters
c
      icycle = nm1
      toleps = rtol + rteps
      rtleps = rtolsq + epsmch
      gnorm  = dsqrt(gtg)
      difnew = zero
      epsred = 5.0d-2
      fkeep  = fnew
c
c set the diagonal of the approximate hessian to unity.
c
      idiagb = ldiagb
      do 15 i = 1,n
         w(idiagb) = one
         idiagb = idiagb + 1
15    continue
c
c ..................start of main iterative loop..........
c
c compute the new search direction
c
      modet = msglvl - 3
      call modlnp(modet,w(lpk),w(lgv),w(lz1),w(lv),
     *     w(ldiagb),w(lemat),x,g,w(lzk),
     *     n,w,lw,niter,maxit,nfeval,nmodif,
     *     nlincg,upd1,yksk,gsk,yrsr,lreset,sfun,.true.,ipivot,
     *     accrcy,gtpnew,gnorm,xnorm)
20    continue
      call dcopy(n,g,1,w(loldg),1)
      pnorm = dnrm2(n,w(lpk),1)
      oldf = fnew
      oldgtp = gtpnew
c
c prepare to compute the step length
c
      pe = pnorm + epsmch
c
c compute the absolute and relative tolerances for the linear search
c
      reltol = rteps*(xnorm + one)/pe
      abstol = - epsmch*ftest/(oldgtp - epsmch)
c
c compute the smallest allowable spacing between points in
c the linear search
c
      tnytol = epsmch*(xnorm + one)/pe
      call stpmax(stepmx,pe,spe,n,x,w(lpk),ipivot,low,up)
c
c set the initial step length.
c
      alpha = step1(fnew,fm,oldgtp,spe)
c
c perform the linear search
c
      call linder(n,sfun,small,epsmch,reltol,abstol,tnytol,
     *     eta,zero,spe,w(lpk),oldgtp,x,fnew,alpha,g,numf,
     *     nwhy,w,lw)
      newcon = .false.
      if (dabs(alpha-spe) .gt. 1.d1*epsmch) go to 30
      newcon = .true.
      nwhy   = 0
      call modz(n,x,w(lpk),ipivot,epsmch,low,up,flast,fnew)
      flast = fnew
c
30    if (msglvl .ge. 2) write(*,820) alpha,pnorm
      fold = fnew
      niter = niter + 1
      nftotl = nftotl + numf
c
c if required, print the details of this iteration
c
      if (msglvl .ge. 1)
     *    call monit(n,x,fnew,g,niter,nftotl,nfeval,lreset,ipivot)
      if (nwhy .lt. 0) go to 160
      if (nwhy .eq. 0 .or. nwhy .eq. 2) go to 40
c
c the linear search has failed to find a lower point
c
      nwhy = 3
      go to 140
40    if (nwhy .le. 1) go to 50
      call sfun(n,x,fnew,g)
      nftotl = nftotl + 1
c
c terminate if more than maxfun evaluations have been made
c
50    nwhy = 2
      if (nftotl .gt. maxfun) go to 150
      nwhy = 0
c
c set up parameters used in convergence and resetting tests
c
      difold = difnew
      difnew = oldf - fnew
c
c if this is the first iteration of a new cycle, compute the
c percentage reduction factor for the resetting test.
c
      if (icycle .ne. 1) go to 60
      if (difnew .gt. 2.d0*difold) epsred = epsred + epsred
      if (difnew .lt. 5.0d-1*difold) epsred = 5.0d-1*epsred
60    call dcopy(n,g,1,w(lgv),1)
      call ztime(n,w(lgv),ipivot)
      gtg = ddot(n,w(lgv),1,w(lgv),1)
      gnorm = dsqrt(gtg)
      ftest = one + dabs(fnew)
      xnorm = dnrm2(n,x,1)
c
c test for convergence
c
      call cnvtst(conv,alpha,pnorm,toleps,xnorm,difnew,rtleps,
     *     ftest,gtg,peps,epsmch,gtpnew,fnew,flast,g,ipivot,n,accrcy)
      if (conv) go to 130
      call ztime(n,g,ipivot)
c
c compute the change in the iterates and the corresponding change
c in the gradients
c
      if (newcon) go to 90
      isk = lsk
      ipk = lpk
      iyk = lyk
      ioldg = loldg
      do 70 i = 1,n
         w(iyk) = g(i) - w(ioldg)
         w(isk) = alpha*w(ipk)
         ipk = ipk + 1
         isk = isk + 1
         iyk = iyk + 1
         ioldg = ioldg + 1
70    continue
c
c set up parameters used in updating the preconditioning strategy.
c
      yksk = ddot(n,w(lyk),1,w(lsk),1)
      lreset = .false.
      if (icycle .eq. nm1 .or. difnew .lt.
     *     epsred*(fkeep-fnew)) lreset = .true.
      if (lreset) go to 80
      yrsr = ddot(n,w(lyr),1,w(lsr),1)
      if (yrsr .le. zero) lreset = .true.
80    continue
      upd1 = .false.
c
c      compute the new search direction
c
90    if (upd1 .and. msglvl .ge. 2) write(*,830)
      if (newcon .and. msglvl .ge. 2) write(*,840)
      modet = msglvl - 3
      call modlnp(modet,w(lpk),w(lgv),w(lz1),w(lv),
     *     w(ldiagb),w(lemat),x,g,w(lzk),
     *     n,w,lw,niter,maxit,nfeval,nmodif,
     *     nlincg,upd1,yksk,gsk,yrsr,lreset,sfun,.true.,ipivot,
     *     accrcy,gtpnew,gnorm,xnorm)
      if (newcon) go to 20
      if (lreset) go to 110
c
c compute the accumulated step and its corresponding
c gradient difference.
c
      call dxpy(n,w(lsk),1,w(lsr),1)
      call dxpy(n,w(lyk),1,w(lyr),1)
      icycle = icycle + 1
      goto 20
c
c reset
c
110   ireset = ireset + 1
c
c initialize the sum of all the changes in x.
c
      call dcopy(n,w(lsk),1,w(lsr),1)
      call dcopy(n,w(lyk),1,w(lyr),1)
      fkeep = fnew
      icycle = 1
      go to 20
c
c ...............end of main iteration.......................
c
130   ifail = 0
      f = fnew
      goto 170
140   oldf = fnew
c
c local search could be installed here
c
150   f = oldf
      if (msglvl .ge. 1) call monit(n,x,
     *     f,g,niter,nftotl,nfeval,.true.,ipivot)
c
c set ifail
c
160   ifail = nwhy


170   if (msglvl .ge. 1 .and. ifail .lt. 0) then
	      if (ifail .ne. 0) write(*,850) ifail
	      return
      endif
      if (msglvl .ge. 1) then
	      if (ifail .ne. 0) write(*,850) ifail
	      write(*,860) f
	      write(*,870)
	      nmax = 10
	      if (n .lt. nmax) nmax = n
	      write(*,880) (i,x(i),i=1,nmax)
      endif
      return



800   format(' there is no feasible point; terminating algorithm')
810   format(//'  nit   nf   cg', 9x, 'f', 21x, 'gtg',//)
820   format('        linesearch results:  alpha,pnorm',2(1pd12.4))
830   format(' upd1 is true - trivial preconditioning')
840   format(' newcon is true - constraint added in linesearch')
850   format(//,' error code =', i3)
860   format(//,' optimal function value = ', 1pd22.15)
870   format(10x, 'current solution is (at most 10 components)', /,
     *       14x, 'i', 11x, 'x(i)')
880   format(10x, i5, 2x, 1pd22.15)

      end
c
c
      subroutine monit(n,x,f,g,niter,nftotl,nfeval,lreset,ipivot)
c
c print results of current iteration
c
      implicit         double precision (a-h,o-z)
      double precision x(n),f,g(n),gtg
      integer          ipivot(n)
      logical          lreset
c
      gtg = 0.d0
      do 10 i = 1,n
         if (ipivot(i) .ne. 0) go to 10
         gtg = gtg + g(i)*g(i)
10    continue
      write(*,800) niter,nftotl,nfeval,f,gtg
      return
800   format(' ',i4,1x,i4,1x,i4,1x,1pd22.15,2x,1pd15.8)
      end
c
c
      subroutine ztime(n,x,ipivot)
      implicit         double precision (a-h,o-z)
      double precision x(n)
      integer          ipivot(n)
c
c this routine multiplies the vector x by the constraint matrix z
c
      do 10 i = 1,n
         if (ipivot(i) .ne. 0) x(i) = 0.d0
10    continue
      return
      end
c
c
      subroutine stpmax(stepmx,pe,spe,n,x,p,ipivot,low,up)
      implicit         double precision (a-h,o-z)
      double precision low(n),up(n),x(n),p(n),stepmx,pe,spe,t
      integer          ipivot(n)
c
c compute the maximum allowable step length
c
      spe = stepmx / pe
c spe is the standard (unconstrained) max step
      do 10 i = 1,n
         if (ipivot(i) .ne. 0) go to 10
         if (p(i) .eq. 0.d0) go to 10
         if (p(i) .gt. 0.d0) go to 5
         t = low(i) - x(i)
         if (t .gt. spe*p(i)) spe = t / p(i)
         go to 10
5        t = up(i) - x(i)
         if (t .lt. spe*p(i)) spe = t / p(i)
10    continue
      return
      end
c
c
      subroutine modz(n,x,p,ipivot,epsmch,low,up,flast,fnew)
      implicit         double precision (a-h,o-z)
      double precision x(n), p(n), epsmch, dabs, tol, low(n), up(n),
     *                 flast, fnew
      integer          ipivot(n)
c
c update the constraint matrix if a new constraint is encountered
c
      do 10 i = 1,n
         if (ipivot(i) .ne. 0) go to 10
         if (p(i) .eq. 0.d0) go to 10
         if (p(i) .gt. 0.d0) go to 5
         tol = 1.d1 * epsmch * (dabs(low(i)) + 1.d0)
         if (x(i)-low(i) .gt. tol) go to 10
         flast = fnew
         ipivot(i) = -1
         x(i) = low(i)
         go to 10
5        tol = 1.d1 * epsmch * (dabs(up(i)) + 1.d0)
         if (up(i)-x(i) .gt. tol) go to 10
         flast = fnew
         ipivot(i) = 1
         x(i) = up(i)
10    continue
      return
      end
c
c
      subroutine cnvtst(conv,alpha,pnorm,toleps,xnorm,difnew,rtleps,
     *     ftest,gtg,peps,epsmch,gtpnew,fnew,flast,g,ipivot,n,accrcy)
      implicit double precision (a-h,o-z)
      logical conv,ltest
      integer ipivot(n)
      double precision g(n), alpha, pnorm, toleps, xnorm, difnew,
     *     rtleps, ftest, gtg, peps, epsmch, gtpnew, fnew, flast, one,
     *     cmax, t, accrcy
c
c test for convergence
c
      imax = 0
      cmax = 0.d0
      ltest = flast - fnew .le. -5.d-1*gtpnew
      do 10 i = 1,n
         if (ipivot(i) .eq. 0 .or. ipivot(i) .eq. 2) go to 10
         t = -ipivot(i)*g(i)
         if (t .ge. 0.d0) go to 10
         conv = .false.
         if (ltest) go to 10
         if (cmax .le. t) go to 10
         cmax = t
         imax = i
10    continue
      if (imax .eq. 0) go to 15
      ipivot(imax) = 0
      flast = fnew
      return
15    continue
      conv = .false.
      one = 1.d0
      if ((alpha*pnorm .ge. toleps*(one + xnorm)
     *     .or. dabs(difnew) .ge. rtleps*ftest
     *     .or. gtg .ge. peps*ftest*ftest)
     *     .and. gtg .ge. 1.d-4*accrcy*ftest*ftest) return
      conv = .true.
c
c for details, see gill, murray, and wright (1981, p. 308) and
c fletcher (1981, p. 116).  the multiplier tests (here, testing
c the sign of the components of the gradient) may still need to
c modified to incorporate tolerances for zero.
c
      return
      end
c
c
      subroutine crash(n,x,ipivot,low,up,ier)
      implicit double precision (a-h,o-z)
      double precision x(n),low(n),up(n)
      integer ipivot(n)
c
c this initializes the constraint information, and ensures that the
c initial point satisfies  low <= x <= up.
c the constraints are checked for consistency.
c
      ier = 0
      do 30 i = 1,n
         if (x(i) .lt. low(i)) x(i) = low(i)
         if (x(i) .gt. up(i)) x(i) = up(i)
         ipivot(i) = 0
         if (x(i) .eq. low(i)) ipivot(i) = -1
         if (x(i) .eq. up(i)) ipivot(i) = 1
         if (up(i) .eq. low(i)) ipivot(i) = 2
         if (low(i) .gt. up(i)) ier = -i
30    continue
      return
      end
c
c the vectors sk and yk, although not in the call,
c are used (via their position in w) by the routine msolve.
c
      subroutine modlnp(modet,zsol,gv,r,v,diagb,emat,
     *     x,g,zk,n,w,lw,niter,maxit,nfeval,nmodif,nlincg,
     *     upd1,yksk,gsk,yrsr,lreset,sfun,bounds,ipivot,accrcy,
     *     gtp,gnorm,xnorm)
      implicit double precision (a-h,o-z)
      integer modet,n,niter,ipivot(1)
      double precision zsol(n),g(n),gv(n),r(n),v(n),diagb(n),w(lw)
      double precision emat(n),zk(n),x(n),accrcy
      double precision alpha,beta,delta,gsk,gtp,pr,
     *     qold,qnew,qtest,rhsnrm,rnorm,rz,rzold,tol,vgv,yksk,yrsr
      double precision gnorm,xnorm
      double precision ddot,dnrm2
      logical first,upd1,lreset,bounds
      external sfun
c
c this routine performs a preconditioned conjugate-gradient
c iteration in order to solve the newton equations for a search
c direction for a truncated-newton algorithm.  when the value of the
c quadratic model is sufficiently reduced,
c the iteration is terminated.
c
c parameters
c
c modet       - integer which controls amount of output
c zsol        - computed search direction
c g           - current gradient
c gv,gz1,v    - scratch vectors
c r           - residual
c diagb,emat  - diagonal preconditoning matrix
c niter       - nonlinear iteration #
c feval       - value of quadratic function
c
c *************************************************************
c initialization
c *************************************************************
c
c general initialization
c
      if (modet .gt. 0) write(*,800)
      if (maxit .eq. 0) return
      first = .true.
      rhsnrm = gnorm
      tol = 1.d-12
      qold = 0.d0
c
c initialization for preconditioned conjugate-gradient algorithm
c
      call initpc(diagb,emat,n,w,lw,modet,
     *            upd1,yksk,gsk,yrsr,lreset)
      do 10 i = 1,n
         r(i) = -g(i)
         v(i) = 0.d0
         zsol(i) = 0.d0
10    continue
c
c ************************************************************
c main iteration
c ************************************************************
c
      do 30 k = 1,maxit
         nlincg = nlincg + 1
         if (modet .gt. 1) write(*,810) k
c
c cg iteration to solve system of equations
c
         if (bounds) call ztime(n,r,ipivot)
         call msolve(r,zk,n,w,lw,upd1,yksk,gsk,
     *                 yrsr,lreset,first)
         if (bounds) call ztime(n,zk,ipivot)
         rz = ddot(n,r,1,zk,1)
         if (rz/rhsnrm .lt. tol) go to 80
         if (k .eq. 1) beta = 0.d0
         if (k .gt. 1) beta = rz/rzold
         do 20 i = 1,n
            v(i) = zk(i) + beta*v(i)
20       continue
         if (bounds) call ztime(n,v,ipivot)
         call gtims(v,gv,n,x,g,w,lw,sfun,first,delta,accrcy,xnorm)
         if (bounds) call ztime(n,gv,ipivot)
         nfeval = nfeval + 1
         vgv = ddot(n,v,1,gv,1)
         if (vgv/rhsnrm .lt. tol) go to 50
         call ndia3(n,emat,v,gv,r,vgv,modet)
c
c compute linear step length
c
         alpha = rz / vgv
         if (modet .ge. 1) write(*,820) alpha
c
c compute current solution and related vectors
c
         call daxpy(n,alpha,v,1,zsol,1)
         call daxpy(n,-alpha,gv,1,r,1)
c
c test for convergence
c
         gtp = ddot(n,zsol,1,g,1)
         pr = ddot(n,r,1,zsol,1)
         qnew = 5.d-1 * (gtp + pr)
         qtest = k * (1.d0 - qold/qnew)
         if (qtest .lt. 0.d0) go to 70
         qold = qnew
         if (qtest .le. 5.d-1) go to 70
c
c perform cautionary test
c
         if (gtp .gt. 0) go to 40
         rzold = rz
30    continue
c
c terminate algorithm
c
      k = k-1
      go to 70
c
c truncate algorithm in case of an emergency
c
40    if (modet .ge. -1) write(*,830) k
      call daxpy(n,-alpha,v,1,zsol,1)
      gtp = ddot(n,zsol,1,g,1)
      go to 90
50    continue
      if (modet .gt. -2) write(*,840)
60    if (k .gt. 1) go to 70
      call msolve(g,zsol,n,w,lw,upd1,yksk,gsk,yrsr,lreset,first)
      call negvec(n,zsol)
      if (bounds) call ztime(n,zsol,ipivot)
      gtp = ddot(n,zsol,1,g,1)
70    continue
      if (modet .ge. -1) write(*,850) k,rnorm
      go to 90
80    continue
      if (modet .ge. -1) write(*,860)
      if (k .gt. 1) go to 70
      call dcopy(n,g,1,zsol,1)
      call negvec(n,zsol)
      if (bounds) call ztime(n,zsol,ipivot)
      gtp = ddot(n,zsol,1,g,1)
      go to 70
c
c store (or restore) diagonal preconditioning
c
90    continue
      call dcopy(n,emat,1,diagb,1)
      return
800   format(' ',//,' entering modlnp')
810   format(' ',//,' ### iteration ',i2,' ###')
820   format(' alpha',1pd16.8)
830   format(' g(t)z positive at iteration ',i2,
     *     ' - truncating method',/)
840   format(' ',10x,'hessian not positive-definite')
850   format(' ',/,8x,'modlan truncated after ',i3,' iterations',
     *     '  rnorm = ',1pd14.6)
860   format(' preconditioning not positive-definite')
      end
c
c
      subroutine ndia3(n,e,v,gv,r,vgv,modet)
      implicit double precision (a-h,o-z)
      double precision e(n),v(n),gv(n),r(n),vgv,vr,ddot
c
c update the preconditioing matrix based on a diagonal version
c of the bfgs quasi-newton update.
c
      vr = ddot(n,v,1,r,1)
      do 10 i = 1,n
         e(i) = e(i) - r(i)*r(i)/vr + gv(i)*gv(i)/vgv
         if (e(i) .gt. 1.d-6) go to 10
         if (modet .gt. -2) write(*,800) e(i)
         e(i) = 1.d0
10    continue
      return
800   format(' *** emat negative:  ',1pd16.8)
      end
c
c      service routines for optimization
c
      subroutine negvec(n,v)
      implicit double precision (a-h,o-z)
      integer n
      double precision v(n)
c
c negative of the vector v
c
      integer i
      do 10 i = 1,n
         v(i) = -v(i)
10    continue
      return
      end
c
c
      subroutine lsout(iloc,itest,xmin,fmin,gmin,xw,fw,gw,u,a,
     *     b,tol,eps,scxbd,xlamda)
      implicit double precision (a-h,o-z)
      double precision xmin,fmin,gmin,xw,fw,gw,u,a,b,
     *     tol,eps,scxbd,xlamda
c
c error printouts for getptc
c
      double precision ya,yb,ybnd,yw,yu
      yu = xmin + u
      ya = a + xmin
      yb = b + xmin
      yw = xw + xmin
      ybnd = scxbd + xmin
      write(*,800)
      write(*,810) tol,eps
      write(*,820) ya,yb
      write(*,830) ybnd
      write(*,840) yw,fw,gw
      write(*,850) xmin,fmin,gmin
      write(*,860) yu
      write(*,870) iloc,itest
      return
800   format(///' output from linear search')
810   format('  tol and eps'/2d25.14)
820   format('  current upper and lower bounds'/2d25.14)
830   format('  strict upper bound'/d25.14)
840   format('  xw, fw, gw'/3d25.14)
850   format('  xmin, fmin, gmin'/3d25.14)
860   format('  new estimate'/2d25.14)
870   format('  iloc and itest'/2i3)
      end
c
c
      double precision function step1(fnew,fm,gtp,smax)
      implicit double precision (a-h,o-z)
      double precision fnew,fm,gtp,smax
c
c ********************************************************
c step1 returns the length of the initial step to be taken along the
c vector p in the next linear search.
c ********************************************************
c
      double precision alpha,d,epsmch
      double precision dabs,mchpr1
      epsmch = mchpr1()
      d = dabs(fnew-fm)
      alpha = 1.d0
      if (2.d0*d .le. (-gtp) .and. d .ge. epsmch)
     *     alpha = -2.d0*d/gtp
      if (alpha .ge. smax) alpha = smax
      step1 = alpha
      return
      end
c
c
      double precision function mchpr1()
      implicit double precision (a-h,o-z)
      double precision x
c
c returns the value of epsmch, where epsmch is the smallest possible
c real number such that 1.0 + epsmch .gt. 1.0
c
c for vax
c
c     mchpr1 = 1.d-17
c
c for sun
c
c     mchpr1 = 1.0842021724855d-19
c win32
      mchpr1 = 2.2204460492503131d-16 
      return
      end
c
c
      subroutine chkucp(lwtest,maxfun,nwhy,n,alpha,epsmch,
     *     eta,peps,rteps,rtol,rtolsq,stepmx,test,
     *     xtol,xnorm,x,lw,small,tiny,accrcy)
      implicit double precision (a-h,o-z)
      integer lw,lwtest,maxfun,nwhy,n
      double precision accrcy,alpha,epsmch,eta,peps,rteps,rtol,
     *     rtolsq,stepmx,test,xtol,xnorm,small,tiny
      double precision x(n)
c
c checks parameters and sets constants which are common to both
c derivative and non-derivative algorithms
c
      double precision dabs,dsqrt,mchpr1
      epsmch = mchpr1()
      small = epsmch*epsmch
      tiny = small
      nwhy = -1
      rteps = dsqrt(epsmch)
      rtol = xtol
      if (dabs(rtol) .lt. accrcy) rtol = 1.d1*rteps
c
c check for errors in the input parameters
c
      if (lw .lt. lwtest
     *      .or. n .lt. 1 .or. rtol .lt. 0.d0 .or. eta .ge. 1.d0 .or.
     *      eta .lt. 0.d0 .or. stepmx .lt. rtol .or.
     *      maxfun .lt. 1) return
      nwhy = 0
c
c set constants for later
c
      rtolsq = rtol*rtol
      peps = accrcy**0.6666d0
      xnorm = dnrm2(n,x,1)
      alpha = 0.d0
      test = 0.d0
      return
      end
c
c
      subroutine setucr(small,nftotl,niter,n,f,fnew,
     *            fm,gtg,oldf,sfun,g,x)
      implicit         double precision (a-h,o-z)
      integer          nftotl,niter,n
      double precision f,fnew,fm,gtg,oldf,small
      double precision g(n),x(n)
      external         sfun
c
c check input parameters, compute the initial function value, set
c constants for the subsequent minimization
c
      fm = f
c
c compute the initial function value
c
      call sfun(n,x,fnew,g)
      nftotl = 1
c
c set constants for later
c
      niter = 0
      oldf = fnew
      gtg = ddot(n,g,1,g,1)
      return
      end
c
c
      subroutine gtims(v,gv,n,x,g,w,lw,sfun,first,delta,accrcy,xnorm)
      implicit double precision (a-h,o-z)
      double precision v(n),gv(n),dinv,delta,g(n)
      double precision f,x(n),w(lw),accrcy,dsqrt,xnorm
      logical first
      external sfun
      common/subscr/ lgv,lz1,lzk,lv,lsk,lyk,ldiagb,lsr,lyr,
     *     lhyr,lhg,lhyk,lpk,lemat,lwtest
c
c this routine computes the product of the matrix g times the vector
c v and stores the result in the vector gv (finite-difference version)
c
      if (.not. first) go to 20
      delta = dsqrt(accrcy)*(1.d0+xnorm)
      first = .false.
20    continue
      dinv = 1.d0/delta
      ihg = lhg
      do 30 i = 1,n
         w(ihg) = x(i) + delta*v(i)
         ihg = ihg + 1
30    continue
      call sfun(n,w(lhg),f,gv)
      do 40 i = 1,n
         gv(i) = (gv(i) - g(i))*dinv
40    continue
      return
      end
c
c
      subroutine msolve(g,y,n,w,lw,upd1,yksk,gsk,
     *     yrsr,lreset,first)
      implicit double precision (a-h,o-z)
      double precision g(n),y(n),w(lw),yksk,gsk,yrsr
      logical upd1,lreset,first
c
c this routine sets upt the arrays for mslv
c
      common/subscr/ lgv,lz1,lzk,lv,lsk,lyk,ldiagb,lsr,lyr,
     *     lhyr,lhg,lhyk,lpk,lemat,lwtest
      call mslv(g,y,n,w(lsk),w(lyk),w(ldiagb),w(lsr),w(lyr),w(lhyr),
     *     w(lhg),w(lhyk),upd1,yksk,gsk,yrsr,lreset,first)
      return
      end
      subroutine mslv(g,y,n,sk,yk,diagb,sr,yr,hyr,hg,hyk,
     *     upd1,yksk,gsk,yrsr,lreset,first)
      implicit double precision (a-h,o-z)
      double precision g(n),y(n)
c
c this routine acts as a preconditioning step for the
c linear conjugate-gradient routine.  it is also the
c method of computing the search direction from the
c gradient for the non-linear conjugate-gradient code.
c it represents a two-step self-scaled bfgs formula.
c
      double precision ddot,yksk,gsk,yrsr,rdiagb,ykhyk,ghyk,
     *     yksr,ykhyr,yrhyr,gsr,ghyr
      double precision sk(n),yk(n),diagb(n),sr(n),yr(n),hyr(n),hg(n),
     *     hyk(n),one
      logical lreset,upd1,first
      if (upd1) go to 100
      one = 1.d0
      gsk = ddot(n,g,1,sk,1)
      if (lreset) go to 60
c
c compute hg and hy where h is the inverse of the diagonals
c
      do 57 i = 1,n
         rdiagb = 1.0d0/diagb(i)
         hg(i) = g(i)*rdiagb
         if (first) hyk(i) = yk(i)*rdiagb
         if (first) hyr(i) = yr(i)*rdiagb
57    continue
      if (first) yksr = ddot(n,yk,1,sr,1)
      if (first) ykhyr = ddot(n,yk,1,hyr,1)
      gsr = ddot(n,g,1,sr,1)
      ghyr = ddot(n,g,1,hyr,1)
      if (first) yrhyr = ddot(n,yr,1,hyr,1)
      call ssbfgs(n,one,sr,yr,hg,hyr,yrsr,
     *     yrhyr,gsr,ghyr,hg)
      if (first) call ssbfgs(n,one,sr,yr,hyk,hyr,yrsr,
     *     yrhyr,yksr,ykhyr,hyk)
      ykhyk = ddot(n,hyk,1,yk,1)
      ghyk = ddot(n,hyk,1,g,1)
      call ssbfgs(n,one,sk,yk,hg,hyk,yksk,
     *     ykhyk,gsk,ghyk,y)
      return
60    continue
c
c compute gh and hy where h is the inverse of the diagonals
c
      do 65 i = 1,n
         rdiagb = 1.d0/diagb(i)
         hg(i) = g(i)*rdiagb
         if (first) hyk(i) = yk(i)*rdiagb
65    continue
      if (first) ykhyk = ddot(n,yk,1,hyk,1)
      ghyk = ddot(n,g,1,hyk,1)
      call ssbfgs(n,one,sk,yk,hg,hyk,yksk,
     *     ykhyk,gsk,ghyk,y)
      return
100   continue
      do 110 i = 1,n
110      y(i) = g(i) / diagb(i)
      return
      end
c
c
      subroutine ssbfgs(n,gamma,sj,yj,hjv,hjyj,yjsj,yjhyj,
     *     vsj,vhyj,hjp1v)
      implicit double precision (a-h,o-z)
      integer n
      double precision gamma,yjsj,yjhyj,vsj,vhyj
      double precision sj(n),yj(n),hjv(n),hjyj(n),hjp1v(n)
c
c self-scaled bfgs
c
      integer i
      double precision beta,delta
      delta = (1.d0 + gamma*yjhyj/yjsj)*vsj/yjsj
     *     - gamma*vhyj/yjsj
      beta = -gamma*vsj/yjsj
      do 10 i = 1,n
         hjp1v(i) = gamma*hjv(i) + delta*sj(i) + beta*hjyj(i)
10    continue
      return
      end
c
c routines to initialize preconditioner
c
      subroutine initpc(diagb,emat,n,w,lw,modet,
     *     upd1,yksk,gsk,yrsr,lreset)
      implicit double precision (a-h,o-z)
      double precision diagb(n),emat(n),w(lw)
      double precision yksk,gsk,yrsr
      logical lreset,upd1
      common/subscr/ lgv,lz1,lzk,lv,lsk,lyk,ldiagb,lsr,lyr,
     *     lhyr,lhg,lhyk,lpk,lemat,lwtest
      call initp3(diagb,emat,n,lreset,yksk,yrsr,w(lhyk),
     *     w(lsk),w(lyk),w(lsr),w(lyr),modet,upd1)
      return
      end
      subroutine initp3(diagb,emat,n,lreset,yksk,yrsr,bsk,
     *     sk,yk,sr,yr,modet,upd1)
      implicit double precision (a-h,o-z)
      double precision diagb(n),emat(n),yksk,yrsr,bsk(n),sk(n),
     *     yk(n),cond,sr(n),yr(n),ddot,sds,srds,yrsk,td,d1,dn
      logical lreset,upd1
      if (upd1) go to 90
      if (lreset) go to 60
      do 10 i = 1,n
         bsk(i) = diagb(i)*sr(i)
10    continue
      sds = ddot(n,sr,1,bsk,1)
      srds = ddot(n,sk,1,bsk,1)
      yrsk = ddot(n,yr,1,sk,1)
      do 20 i = 1,n
         td = diagb(i)
         bsk(i) = td*sk(i) - bsk(i)*srds/sds+yr(i)*yrsk/yrsr
         emat(i) = td-td*td*sr(i)*sr(i)/sds+yr(i)*yr(i)/yrsr
20    continue
      sds = ddot(n,sk,1,bsk,1)
      do 30 i = 1,n
         emat(i) = emat(i) - bsk(i)*bsk(i)/sds+yk(i)*yk(i)/yksk
30    continue
      go to 110
60    continue
      do 70 i = 1,n
         bsk(i) = diagb(i)*sk(i)
70    continue
      sds = ddot(n,sk,1,bsk,1)
      do 80 i = 1,n
         td = diagb(i)
         emat(i) = td - td*td*sk(i)*sk(i)/sds + yk(i)*yk(i)/yksk
80    continue
      go to 110
90    continue
      call dcopy(n,diagb,1,emat,1)
110   continue
      if (modet .lt. 1) return
      d1 = emat(1)
      dn = emat(1)
      do 120 i = 1,n
         if (emat(i) .lt. d1) d1 = emat(i)
         if (emat(i) .gt. dn) dn = emat(i)
120   continue
      cond = dn/d1
      write(*,800) d1,dn,cond
800   format(' ',//8x,'dmin =',1pd12.4,'  dmax =',1pd12.4,
     *     ' cond =',1pd12.4,/)
      return
      end
c
c
      subroutine setpar(n)
      implicit double precision (a-h,o-z)
      integer lsub(14)
      common/subscr/ lsub,lwtest
c
c set up parameters for the optimization routine
c
      do 10 i = 1,14
          lsub(i) = (i-1)*n + 1
10    continue
      lwtest = lsub(14) + n - 1
      return
      end
c
c      line search algorithms of gill and murray
c
      subroutine linder(n,sfun,small,epsmch,reltol,abstol,
     *     tnytol,eta,sftbnd,xbnd,p,gtp,x,f,alpha,g,nftotl,
     *     iflag,w,lw)
      implicit double precision (a-h,o-z)
      integer n,nftotl,iflag,lw
      double precision small,epsmch,reltol,abstol,tnytol,eta,
     *     sftbnd,xbnd,gtp,f,alpha
      double precision p(n),x(n),g(n),w(lw)
c
c
      integer i,ientry,itest,l,lg,lx,numf,itcnt
      double precision a,b,b1,big,e,factor,fmin,fpresn,fu,
     *     fw,gmin,gtest1,gtest2,gu,gw,oldf,scxbnd,step,
     *     tol,u,xmin,xw,rmu,rtsmll,ualpha
      logical braktd
c
c      the following standard functions and system functions are
c      called within linder
c
      double precision ddot,dsqrt
      external sfun
c
c      allocate the addresses for local workspace
c
      lx = 1
      lg = lx + n
      lsprnt = 0
      nprnt  = 10000
      rtsmll = dsqrt(small)
      big = 1.d0/small
      itcnt = 0
c
c      set the estimated relative precision in f(x).
c
      fpresn = 10.d0*epsmch
      numf = 0
      u = alpha
      fu = f
      fmin = f
      gu = gtp
      rmu = 1.0d-4
c
c      first entry sets up the initial interval of uncertainty.
c
      ientry = 1
10    continue
c
c test for too many iterations
c
      itcnt = itcnt + 1
      iflag = 1
      if (itcnt .gt. 20) go to 50
      iflag = 0
      call getptc(big,small,rtsmll,reltol,abstol,tnytol,
     *     fpresn,eta,rmu,xbnd,u,fu,gu,xmin,fmin,gmin,
     *     xw,fw,gw,a,b,oldf,b1,scxbnd,e,step,factor,
     *     braktd,gtest1,gtest2,tol,ientry,itest)
clsout
      if (lsprnt .ge. nprnt) call lsout(ientry,itest,xmin,fmin,gmin,
     *     xw,fw,gw,u,a,b,tol,reltol,scxbnd,xbnd)
c
c      if itest=1, the algorithm requires the function value to be
c      calculated.
c
      if (itest .ne. 1) go to 30
      ualpha = xmin + u
      l = lx
      do 20 i = 1,n
         w(l) = x(i) + ualpha*p(i)
         l = l + 1
20    continue
      call sfun(n,w(lx),fu,w(lg))
      numf = numf + 1
      gu = ddot(n,w(lg),1,p,1)
c
c      the gradient vector corresponding to the best point is
c      overwritten if fu is less than fmin and fu is sufficiently
c      lower than f at the origin.
c
      if (fu .le. fmin .and. fu .le. oldf-ualpha*gtest1)
     *     call dcopy(n,w(lg),1,g,1)
      goto 10
c
c      if itest=2 or 3 a lower point could not be found
c
30    continue
      nftotl = numf
      iflag = 1
      if (itest .ne. 0) go to 50
c
c      if itest=0 a successful search has been made
c
      iflag = 0
      f = fmin
      alpha = xmin
      do 40 i = 1,n
         x(i) = x(i) + alpha*p(i)
40    continue
50    return
      end
c
c
      subroutine getptc(big,small,rtsmll,reltol,abstol,tnytol,
     *     fpresn,eta,rmu,xbnd,u,fu,gu,xmin,fmin,gmin,
     *     xw,fw,gw,a,b,oldf,b1,scxbnd,e,step,factor,
     *     braktd,gtest1,gtest2,tol,ientry,itest)
      implicit double precision (a-h,o-z)
      logical braktd
      integer ientry,itest
      double precision big,small,rtsmll,reltol,abstol,tnytol,
     *     fpresn,eta,rmu,xbnd,u,fu,gu,xmin,fmin,gmin,
     *     xw,fw,gw,a,b,oldf,b1,scxbnd,e,step,factor,
     *     gtest1,gtest2,tol,denom
c
c ************************************************************
c getptc, an algorithm for finding a steplength, called repeatedly by
c routines which require a step length to be computed using cubic
c interpolation. the parameters contain information about the interval
c in which a lower point is to be found and from this getptc computes a
c point at which the function can be evaluated by the calling program.
c the value of the integer parameters ientry determines the path taken
c through the code.
c ************************************************************
c
      logical convrg
      double precision abgmin,abgw,absr,a1,chordm,chordu,
     *     d1,d2,p,q,r,s,scale,sumsq,twotol,xmidpt
      double precision zero, point1,half,one,three,five,eleven
c
c the following standard functions and system functions are called
c within getptc
c
      double precision dabs, dsqrt
c
      zero = 0.d0
      point1 = 1.d-1
      half = 5.d-1
      one = 1.d0
      three = 3.d0
      five = 5.d0
      eleven = 11.d0
c
c      branch to appropriate section of code depending on the
c      value of ientry.
c
      goto (10,20), ientry
c
c      ientry=1
c      check input parameters
c
10      itest = 2
      if (u .le. zero .or. xbnd .le. tnytol .or. gu .gt. zero)
     *     return
      itest = 1
      if (xbnd .lt. abstol) abstol = xbnd
      tol = abstol
      twotol = tol + tol
c
c a and b define the interval of uncertainty, x and xw are points
c with lowest and second lowest function values so far obtained.
c initialize a,smin,xw at origin and corresponding values of
c function and projection of the gradient along direction of search
c at values for latest estimate at minimum.
c
      a = zero
      xw = zero
      xmin = zero
      oldf = fu
      fmin = fu
      fw = fu
      gw = gu
      gmin = gu
      step = u
      factor = five
c
c      the minimum has not yet been bracketed.
c
      braktd = .false.
c
c set up xbnd as a bound on the step to be taken. (xbnd is not computed
c explicitly but scxbnd is its scaled value.)  set the upper bound
c on the interval of uncertainty initially to xbnd + tol(xbnd).
c
      scxbnd = xbnd
      b = scxbnd + reltol*dabs(scxbnd) + abstol
      e = b + b
      b1 = b
c
c compute the constants required for the two convergence criteria.
c
      gtest1 = -rmu*gu
      gtest2 = -eta*gu
c
c set ientry to indicate that this is the first iteration
c
      ientry = 2
      go to 210
c
c ientry = 2
c
c update a,b,xw, and xmin
c
20      if (fu .gt. fmin) go to 60
c
c if function value not increased, new point becomes next
c origin and other points are scaled accordingly.
c
      chordu = oldf - (xmin + u)*gtest1
      if (fu .le. chordu) go to 30
c
c the new function value does not satisfy the sufficient decrease
c criterion. prepare to move the upper bound to this point and
c force the interpolation scheme to either bisect the interval of
c uncertainty or take the linear interpolation step which estimates
c the root of f(alpha)=chord(alpha).
c
      chordm = oldf - xmin*gtest1
      gu = -gmin
      denom = chordm-fmin
      if (dabs(denom) .ge. 1.d-15) go to 25
          denom = 1.d-15
          if (chordm-fmin .lt. 0.d0)  denom = -denom
25    continue
      if (xmin .ne. zero) gu = gmin*(chordu-fu)/denom
      fu = half*u*(gmin+gu) + fmin
      if (fu .lt. fmin) fu = fmin
      go to 60
30      fw = fmin
      fmin = fu
      gw = gmin
      gmin = gu
      xmin = xmin + u
      a = a-u
      b = b-u
      xw = -u
      scxbnd = scxbnd - u
      if (gu .le. zero) go to 40
      b = zero
      braktd = .true.
      go to 50
40    a = zero
50    tol = dabs(xmin)*reltol + abstol
      go to 90
c
c if function value increased, origin remains unchanged
c but new point may now qualify as w.
c
60    if (u .lt. zero) go to 70
      b = u
      braktd = .true.
      go to 80
70    a = u
80    xw = u
      fw = fu
      gw = gu
90    twotol = tol + tol
      xmidpt = half*(a + b)
c
c check termination criteria
c
      convrg = dabs(xmidpt) .le. twotol - half*(b-a) .or.
     *     dabs(gmin) .le. gtest2 .and. fmin .lt. oldf .and.
     *     (dabs(xmin - xbnd) .gt. tol .or. .not. braktd)
      if (.not. convrg) go to 100
      itest = 0
      if (xmin .ne. zero) return
c
c if the function has not been reduced, check to see that the relative
c change in f(x) is consistent with the estimate of the delta-
c unimodality constant, tol.  if the change in f(x) is larger than
c expected, reduce the value of tol.
c
      itest = 3
      if (dabs(oldf-fw) .le. fpresn*(one + dabs(oldf))) return
      tol = point1*tol
      if (tol .lt. tnytol) return
      reltol = point1*reltol
      abstol = point1*abstol
      twotol = point1*twotol
c
c continue with the computation of a trial step length
c
100   r = zero
      q = zero
      s = zero
      if (dabs(e) .le. tol) go to 150
c
c fit cubic through xmin and xw
c
      r = three*(fmin-fw)/xw + gmin + gw
      absr = dabs(r)
      q = absr
      if (gw .eq. zero .or. gmin .eq. zero) go to 140
c
c compute the square root of (r*r - gmin*gw) in a way
c which avoids underflow and overflow.
c
      abgw = dabs(gw)
      abgmin = dabs(gmin)
      s = dsqrt(abgmin)*dsqrt(abgw)
      if ((gw/abgw)*gmin .gt. zero) go to 130
c
c compute the square root of r*r + s*s.
c
      sumsq = one
      p = zero
      if (absr .ge. s) go to 110
c
c there is a possibility of overflow.
c
      if (s .gt. rtsmll) p = s*rtsmll
      if (absr .ge. p) sumsq = one +(absr/s)**2
      scale = s
      go to 120
c
c there is a possibility of underflow.
c
110   if (absr .gt. rtsmll) p = absr*rtsmll
      if (s .ge. p) sumsq = one + (s/absr)**2
      scale = absr
120   sumsq = dsqrt(sumsq)
      q = big
      if (scale .lt. big/sumsq) q = scale*sumsq
      go to 140
c
c compute the square root of r*r - s*s
c
130   q = dsqrt(dabs(r+s))*dsqrt(dabs(r-s))
      if (r .ge. s .or. r .le. (-s)) go to 140
      r = zero
      q = zero
      go to 150
c
c compute the minimum of fitted cubic
c
140   if (xw .lt. zero) q = -q
      s = xw*(gmin - r - q)
      q = gw - gmin + q + q
      if (q .gt. zero) s = -s
      if (q .le. zero) q = -q
      r = e
      if (b1 .ne. step .or. braktd) e = step
c
c construct an artificial bound on the estimated steplength
c
150   a1 = a
      b1 = b
      step = xmidpt
      if (braktd) go to 160
      step = -factor*xw
      if (step .gt. scxbnd) step = scxbnd
      if (step .ne. scxbnd) factor = five*factor
      go to 170
c
c if the minimum is bracketed by 0 and xw the step must lie
c within (a,b).
c
160   if ((a .ne. zero .or. xw .ge. zero) .and. (b .ne. zero .or.
     *     xw .le. zero)) go to 180
c
c if the minimum is not bracketed by 0 and xw the step must lie
c within (a1,b1).
c
      d1 = xw
      d2 = a
      if (a .eq. zero) d2 = b
c this line might be
c     if (a .eq. zero) d2 = e
      u = - d1/d2
      step = five*d2*(point1 + one/u)/eleven
      if (u .lt. one) step = half*d2*dsqrt(u)
170   if (step .le. zero) a1 = step
      if (step .gt. zero) b1 = step
c
c reject the step obtained by interpolation if it lies outside the
c required interval or it is greater than half the step obtained
c during the last-but-one iteration.
c
180   if (dabs(s) .le. dabs(half*q*r) .or.
     *     s .le. q*a1 .or. s .ge. q*b1) go to 200
c
c a cubic interpolation step
c
      step = s/q
c
c the function must not be evalutated too close to a or b.
c
      if (step - a .ge. twotol .and. b - step .ge. twotol) go to 210
      if (xmidpt .gt. zero) go to 190
      step = -tol
      go to 210
190   step = tol
      go to 210
200   e = b-a
c
c if the step is too large, replace by the scaled bound (so as to
c compute the new point on the boundary).
c
210   if (step .lt. scxbnd) go to 220
      step = scxbnd
c
c move sxbd to the left so that sbnd + tol(xbnd) = xbnd.
c
      scxbnd = scxbnd - (reltol*dabs(xbnd)+abstol)/(one + reltol)
220   u = step
      if (dabs(step) .lt. tol .and. step .lt. zero) u = -tol
      if (dabs(step) .lt. tol .and. step .ge. zero) u = tol
      itest = 1
      return
      end
