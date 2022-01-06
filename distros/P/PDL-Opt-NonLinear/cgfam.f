
c
c     --------------------------------------------------------------------
c     conjugate gradient methods for solving unconstrained nonlinear
c     optimization problems, as described in the paper:
c
c     gilbert, j.c. and nocedal, j. (1992). "global convergence properties 
c     of conjugate gradient methods", siam journal on optimization, vol. 2,
c     pp. 21-42. 
c
c     a web-based server which solves unconstrained nonlinear optimization
c     problems using this conjugate gradient code can be found at:
c
c       http://www-neos.mcs.anl.gov/neos/solvers/uco:cgplus/
c
c     --------------------------------------------------------------------
c
      subroutine cgfam(n,x,f,g,d,gold,iprint,eps,xtol,gtol,w,
     *                  iflag,irest,method,finish )
c
c subroutine parameters
c
      double precision x(n),g(n),d(n),gold(n),w(n),f,eps,gtol,xtol
      integer n,iprint(2),iflag,irest,method,im,ndes
c
c     n      =  number of variables
c     x      =  iterate
c     f      =  function value
c     g      =  gradient value
c     gold   =  previous gradient value
c     iprint =  frequency and type of printing
c               iprint(1) < 0 : no output is generated
c               iprint(1) = 0 : output only at first and last iteration
c               iprint(1) > 0 : output every iprint(1) iterations
c               iprint(2)     : specifies the type of output generated;
c                               the larger the value (between 0 and 3),
c                               the more information
c               iprint(2) = 0 : no additional information printed
c 		iprint(2) = 1 : initial x and gradient vectors printed
c		iprint(2) = 2 : x vector printed every iteration
c		iprint(2) = 3 : x vector and gradient vector printed 
c				every iteration 
c     eps    =  convergence constant
c     w      =  working array
c     iflag  =  controls termination of code, and return to main
c               program to evaluate function and gradient
c               iflag = -3 : improper input parameters
c               iflag = -2 : descent was not obtained
c               iflag = -1 : line search failure
c               iflag =  0 : initial entry or 
c                            successful termination without error   
c               iflag =  1 : indicates a re-entry with new function values
c               iflag =  2 : indicates a re-entry with a new iterate
c     irest  =  0 (no restarts); 1 (restart every n steps)
c     method =  1 : fletcher-reeves 
c               2 : polak-ribiere
c               3 : positive polak-ribiere ( beta=max{beta,0} )
c
c local variables
c
      double precision one,zero,gnorm,ddot,stp1,ftol,stpmin,
     .       stpmax,stp,beta,betafr,betapr,dg0,gg,gg0,dgold,
     .       dgout,dg,dg1
      integer mp,lp,iter,nfun,maxfev,info,i,nfev,nrst,ides
      logical new,finish,cancel
c
c     the following parameters are placed in common blocks so they
c     can be easily accessed anywhere in the code
c
c     mp = unit number which determines where to write regular output
c     lp = unit number which determines where to write error ouput
      common /cgdd/mp,lp
c
c     iter: keeps track of the number of iterations
c     nfun: keeps track of the number of function/gradient evaluations
      common /runinf/iter,nfun
      save
      data one,zero/1.0d+0,0.0d+0/

      if (method .lt. 1 .or.  method .gt. 3) method = 1
      if (finish) then
      	cancel = .true.
      else
        cancel = .false.
      endif 
c
c iflag = 1 indicates a re-entry with new function values
      if(iflag.eq.1) go to 72
c
c iflag = 2 indicates a re-entry with a new iterate
      if(iflag.eq.2) go to 80
c
c     initialize
c     ----------
c
c
c     im =   number of times betapr was negative for method 2 or
c            number of times betapr was 0 for method 3
c
c     ndes = number of line search iterations after wolfe conditions
c            were satisfied
c
      iter= 0
      if(n.le.0) go to 96
      nfun= 1
      new=.true.
      nrst= 0
      im=0
      ndes=0
c
      do 5 i=1,n
 5    d(i)= -g(i)
      gnorm= dsqrt(ddot(n,g,1,g,1))
      stp1= one/gnorm
c
c     parameters for line search routine
c     ----------------------------------
c
c     ftol and gtol are nonnegative input variables. termination
c       occurs when the sufficient decrease condition and the
c       directional derivative condition are satisfied.
c
c     xtol is a nonnegative input variable. termination occurs
c       when the relative width of the interval of uncertainty
c       is at most xtol.
c
c     stpmin and stpmax are nonnegative input variables which
c       specify lower and upper bounds for the step.
c
c     maxfev is a positive integer input variable. termination
c       occurs when the number of calls to fcn is at least
c       maxfev by the end of an iteration.

      ftol= 1.0d-4
      if(gtol.le.1.d-04) then
        if(lp.gt.0) write(lp,145)
        gtol=1.d-02
      endif
      stpmin= 1.0d-20
      stpmax= 1.0d+20
      maxfev= 40
c
      if(iprint(1).ge.0) call cgbd(iprint,iter,nfun,
     *   gnorm,n,x,f,g,stp,finish,ndes,im,betafr,betapr,beta,cancel)
c
c     main iteration loop
c    ---------------------
c
 8    iter= iter+1
c     when nrst>n and irest=1 then restart
      nrst= nrst+1
      info=0
c
c
c     call the line search routine of mor'e and thuente
c     (modified for our cg method)
c     -------------------------------------------------
c
c       jj mor'e and d thuente, "linesearch algorithms with guaranteed
c       sufficient decrease". acm transactions on mathematical
c       software 20 (1994), pp 286-307.
c
      nfev=0
      do 70 i=1,n
  70  gold(i)= g(i)
      dg= ddot(n,d,1,g,1)
      dgold=dg
      stp=one
c
c shanno-phua's formula for trial step
c
      if(.not.new) stp= dg0/dg
      if (iter.eq.1) stp=stp1
      ides=0
      new=.false.
  72  continue
c
c     write(6,*) 'step= ', stp
c
c call to the line search subroutine
c
      call cvsmod(n,x,f,g,d,stp,ftol,gtol,
     *            xtol,stpmin,stpmax,maxfev,info,nfev,w,dg,dgout)

c       info is an integer output variable set as follows:
c         info = 0  improper input parameters.
c         info =-1  a return is made to compute the function and gradient.
c         info = 1  the sufficient decrease condition and the
c                   directional derivative condition hold.
c         info = 2  relative width of the interval of uncertainty
c                   is at most xtol.
c         info = 3  number of calls to fcn has reached maxfev.
c         info = 4  the step is at the lower bound stpmin.
c         info = 5  the step is at the upper bound stpmax.
c         info = 6  rounding errors prevent further progress.
c                   there may not be a step which satisfies the
c                   sufficient decrease and curvature conditions.
c                   tolerances may be too small.

      if (info .eq. -1) then
c       return to fetch function and gradient
        iflag=1
        return
      endif
      if (info .ne. 1) go to 90
c
c     test if descent direction is obtained for methods 2 and 3
c     ---------------------------------------------------------
c
      gg= ddot(n,g,1,g,1)
      gg0= ddot(n,g,1,gold,1)
      betapr= (gg-gg0)/gnorm**2
      if (irest.eq.1.and.nrst.gt.n) then
        nrst=0
        new=.true.
        go to 75
      endif 
c
      if (method.eq.1) then
        go to 75
      else
        dg1=-gg + betapr*dgout
        if (dg1.lt. 0.0d0 ) go to 75
        if (iprint(1).ge.0) write(6,*) 'no descent'
        ides= ides + 1
        if(ides.gt.5) go to 95
        go to 72
      endif
c
c     determine correct beta value for method chosen
c     ----------------------------------------------
c
c     im =   number of times betapr was negative for method 2 or
c            number of times betapr was 0 for method 3
c
c     ndes = number of line search iterations after wolfe conditions
c            were satisfied
c
  75  nfun= nfun + nfev
      ndes= ndes + ides
      betafr= gg/gnorm**2
      if (nrst.eq.0) then
        beta= zero
      else
        if (method.eq.1) beta=betafr
        if (method.eq.2) beta=betapr
        if ((method.eq.2.or.method.eq.3).and.betapr.lt.0) im=im+1
        if (method.eq.3) beta=max(zero,betapr)
      endif
c
c     compute the new direction
c     --------------------------
c
      do 78 i=1,n
  78  d(i) = -g(i) +beta*d(i)
      dg0= dgold*stp
c
c     return to driver for termination test
c     -------------------------------------
c
      xnorm=dsqrt(ddot(n,x,1,x,1))
      gnorm=dsqrt(ddot(n,g,1,g,1))
      if (gnorm/xnorm .le. eps) then
      	finish=.true.
      else
	iflag=2
        return
      endif


  80  continue
c
c call subroutine for printing output
c
      if(iprint(1).ge.0) call cgbd(iprint,iter,nfun,
     *     gnorm,n,x,f,g,stp,finish,ndes,im,betafr,betapr,beta,cancel)
      if (finish) then
         iflag = 0
         return
      end if
      go to 8
c
c     ----------------------------------------
c     end of main iteration loop. error exits.
c     ----------------------------------------
c
  90  iflag=-1
      if(lp.gt.0) write(lp,100) info
      return
  95  iflag=-2
      if(lp.gt.0) write(lp,135) i
      return
  96  iflag= -3
      if(lp.gt.0) write(lp,140)
c
c     formats
c     -------
c
 100  format(/' iflag= -1 ',/' line search failed. see',
     .          ' documentation of routine cvsmod',/' error return',
     .          ' of line search: info= ',i2,/
     .          ' possible cause: function or gradient are incorrect')
 135  format(/' iflag= -2',/' descent was not obtained')
 140  format(/' iflag= -3',/' improper input parameters (n',
     .       ' is not positive)')
 145  format(/'  gtol is less than or equal to 1.d-04',
     .       / ' it has been reset to 1.d-02')
      return
      end
c
c     last line of routine cgfam
c     ***************************
c
c
c**************************************************************************
      subroutine cgbd(iprint,iter,nfun,
     *           gnorm,n,x,f,g,stp,finish,ndes,im,betafr,betapr,beta,
     *		 cancel)
c
c     ---------------------------------------------------------------------
c     this routine prints monitoring information. the frequency and amount
c     of output are controlled by iprint.
c     ---------------------------------------------------------------------
c
      double precision x(n),g(n),f,gnorm,stp,betafr,betapr,beta
      integer iprint(2),iter,nfun,lp,mp,n,ndes,im
      logical finish,cancel
      common /cgdd/mp,lp
c
      if (iter.eq.0)then
           print*
           write(mp,10)
           write(mp,20) n
           write(mp,30) f,gnorm
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
                     write(mp,80)iter,nfun,f,gnorm,stp,beta
               else
                     return
               endif
          else
               if( iprint(2).gt.1.and.finish) write(mp,70)
               write(mp,80)iter,nfun,f,gnorm,stp,beta
          endif
          if (iprint(2).eq.2.or.iprint(2).eq.3)then
                  write(mp,40)
                  write(mp,50)(x(i),i=1,n)
              if (iprint(2).eq.3)then
                  write(mp,60)
                  write(mp,50)(g(i),i=1,n)
              endif
          endif
          if (finish) then
	  	if (cancel)then
		  write(mp,110)
		else
		  write(mp,100)
		endif
	  endif
      endif
c
 10   format('*************************************************')
 20   format(' n=',i5,//,'initial values:')
 30   format(' f= ',1pd10.3,'   gnorm= ',1pd10.3)
 40   format(/,' vector x= ')
 50   format(6(2x,1pd10.3/))
 60   format(' gradient vector g= ')
 70   format(/'   i  nfn',4x,'func',7x,'gnorm',6x,
     *   'steplen',4x,'beta',/,
     *   ' ----------------------------------------------------')
 80   format(i4,1x,i3,2x,2(1pd10.3,2x),1pd8.1,2x,1pd8.1)
100   format(/' successful convergence (no errors).'
     *          ,/,' iflag = 0')
110   format(/' User canceled optimization.')
c
      return
      end
c     
c     last line of cgbd
c*************************************************************************
c
c
c   ----------------------------------------------------------
c     data 
c   ----------------------------------------------------------
c
c     mp = unit number which determines where to write regular output
c     lp = unit number which determines where to write error ouput
c
      block data cgcd
      common /cgdd/mp,lp
      integer lp,mp
      data mp,lp/6,6/
      end
c
c
c   ----------------------------------------------------------
c
c     last line of cgfam
c*************************************************************************

 



 




