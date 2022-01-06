
c     Last update: March 22th, 2002

c     See report of last modifications at the end of this file.

      subroutine gencan(n,x,l,u,epsgpen,epsgpsn,epsnfp,maxitnfp,
     *maxitngp,fmin,maxit,maxfc,udelta0,ucgmaxit,cgscre,cggpnf,cgepsi,
     *cgepsf,epsnqmp,maxitnqmp,nearlyq,gtype,htvtype,trtype,iprint,
     *iprint2,f,g,gpeucn2,gpsupn,iter,fcnt,gcnt,cgcnt,spgiter,spgfcnt,
     *tniter,tnfcnt,tnstpcnt,tnintcnt,tnexgcnt,tnexbcnt,tnintfe,tnexgfe,
     *tnexbfe,flag,s,y,d,ind,w,eta,delmin,lammax,lammin,theta,gamma,
     *beta,sigma1,sigma2,nint,next,mininterp,ncomp,sterel,steabs,epsrel,
     *epsabs,infty,evalf,evalg,evalhd)

      logical nearlyq

      integer n,maxitnfp,maxitngp,maxit,maxfc,maxitnqmp,ucgmaxit,
     *cgscre,gtype,htvtype,trtype,iprint,iprint2,iter,fcnt,gcnt,cgcnt,
     *spgiter,spgfcnt,tniter,tnfcnt,tnstpcnt,tnintcnt,tnexgcnt,tnexbcnt,
     *tnintfe,tnexgfe,tnexbfe,flag,ind(n),mininterp,ncomp

      double precision x(n),l(n),u(n),epsgpen,epsgpsn,epsnfp,fmin,
     *udelta0,cggpnf,cgepsi,cgepsf,epsnqmp,f,g(n),gpeucn2,gpsupn,s(n),
     *y(n),d(n),w(5*n),eta,delmin,lammax,lammin,theta,gamma,beta,sigma1,
     *sigma2,nint,next,sterel,steabs,epsrel,epsabs,infty
     
      external evalf,evalg,evalhd
c     Solves the box-constrained minimization problem
c
c                  Minimize f(x)
c                  subject to l \leq x \leq u
c
c     using a method described in
c
c     E. G. Birgin and J. M. Martinez, "Large-scale active-set
c     box-constrained optimization method with spectral projected
c     gradients", Computational Optimization and
c     Applications 23, 101-125 (2002).
c
c     Subroutines evalf and evalg must be supplied by the user to
c     evaluate the function f and its gradient, respectively. The
c     calling sequences are
c
c                  call evalf(n, x, f, inform)
c
c                  call evalg(n, x, g, inform)
c
c     where x is the point where the function (the gradient) must be
c     evaluated, n is the number of variables and f (g) is the
c     functional value (the gradient vector). The real parameters
c     x, f, g must be double precision.
c
c     A subroutine evalhd to compute the Hessian times vector products
c     is optional. If this subroutine is not provided an incremental
c     quotients version will be used instead. The calling sequence of
c     this subroutine should be
c
c                  call evalhd(nind,ind,n,x,u,hu,inform)
c
c     where x is the point where the approx-Hessian is being considered,
c     n is the number of variables, u is the vector which should be
c     multiplied by the approx-Hessian H and hu is the vector where the
c     product should be placed. The information about the matrix H must
c     be passed to evalhd by means of common declarations. The necessary
c     computations must be done in evalg. The real parameters x, u, hu
c     must be double precision.
c
c     This subroutine must be coded by the user, taking into account
c     that n is the number of variables of the problem and that hu must
c     be the product H u. Moreover, you must assume, when you code evalhd,
c     that only nind components of u are nonnull and that ind is the set
c     of indices of those components. In other words, you must write
c     evalhd in such a way that hu is the vector whose i-th entry is
c
c               hu(i) = \Sum_{j=1}^{nind} H_{i,ind(j)} u_ind(j)
c
c     Moreover, the only components of hu that you need to compute are
c     those which corresponds to the indices ind(1),...,ind(nind).
c     However, observe that you must assume that, in u, the whole
c     vector is present, with its n components, even the zeroes. So,
c     if you decide to code evalhd without taking into account the
c     presence of ind and nind, you can do it. A final observation:
c     probably, if nind is close to n, it is not worthwhile to use ind,
c     due to the cost of accessing the correct indices. If you want,
c     you can test, within your evalhd, if (say) nind > n/2, and, in
c     this case use a straightforward scalar product for the components
c     of hu.
c
c     Example: Suppose that the matrix H is full. The main steps of
c     evalhd could be:
c
c          do i= 1, nind
c              indi= ind(i)
c              hu(indi)= 0.0d0
c              do j= 1, nind
c                  indj= ind(j)
c                  hu(indi)= hu(indi) + H(indi,indj) * u(indj)
c              end do
c          end do
c
c
c     On Entry
c
c     n    integer
c          the space dimension
c
c     x    double precision x(n)
c          initial estimate to the solution
c
c     l    double precision l(n)
c          lower bounds
c
c     u    double precision u(n)
c          upper bounds
c
c     epsgpen double precision
c          small positive number for declaring convergence when the
c          euclidian norm of the projected gradient is less than
c          or equal to epsgpen
c
c          RECOMMENDED: epsgpen = 1.0d-5
c
c     epsgpsn double precision
c          small positive number for declaring convergence when the
c          infinite norm of the projected gradient is less than
c          or equal to epsgpsn
c
c          RECOMMENDED: epsgpsn = 1.0d-5
c
c     epsnfp double precision
c          ``lack of enough progress'' measure. The algorithm stops by
c          ``lack of enough progress'' when f(x_k) - f(x_{k+1}) <=
c          epsnfp * max { f(x_j)-f(x_{j+1}, j<k} during maxitnfp
c          consecutive iterations. This stopping criterion may be
c          inhibited setting epsnfp = 0. We recommend, preliminary, to
c          set epsnfp = 0.01 and maxitnfp = 5
c
c          RECOMMENDED: epsnfp = 1.0d-2
c
c     maxitnfp integer
c          see the meaning of epsnfp, above
c
c          RECOMMENDED: maxitnfp = 5
c
c     maxitngp integer
c          If the order of the euclidian-norm of the continuous projected
c          gradient did not change during maxitngp consecutive iterations
c          the execution stops. Recommended: maxitngp= 10. In any case
c          maxitngp must be greater than or equal to 1
c
c          RECOMMENDED: maxitngp = 10
c
c     fmin double precision
c          function value for the stopping criteria f <= fmin
c
c          RECOMMENDED: fmin = -1.0d+99 (inhibited)
c
c     maxit integer
c          maximum number of iterations allowed
c
c          RECOMMENDED: maxit = 1000
c
c     maxfc integer
c          maximum number of funtion evaluations allowed
c
c          RECOMMENDED: maxfc = 5000
c
c     udelta0 double precision
c          initial trust-region radius. Default max{0.1||x||,0.1} is set
c          if you set udelta0 < 0. Otherwise, the parameters udelta0
c          will be the ones set by the user.
c
c          RECOMMENDED: udelta0 = -1
c
c     ucgmaxit integer
c          maximum number of iterations allowed for the cg subalgorithm
c
c          Default values for this parameter and the previous one are
c          0.1 and 10 * log (number of free variables). Default values
c          are taken if you set ucgeps < 0 and ucgmaxit < 0,
c          respectively. Otherwise, the parameters ucgeps and ucgmaxit
c          will be the ones set by the user
c
c          RECOMMENDED: ucgmaxit = -1
c
c     cgscre, cggpnf double precision
c          cgscre means cunjugate gradient stopping criterion relation, and
c          cggpnf means conjugate gradients projected gradient final norm.
c          Both are related to a stopping criterion of conjugate gradients.
c          This stopping criterion depends on the norm of the residual
c          of the linear system. The norm of the this residual should be
c          less or equal than a ``small''quantity which decreases as we are
c          approximating the solution of the minimization problem (near the
c          solution, better the truncated-Newton direction we aim). Then, the
c          log of the required precision requested to conjugate gradient has
c          a linear dependence on the log of the norm of the projected
c          gradient. This linear relation uses the squared euclidian-norm
c          of the projected gradient if cgscre = 1 and uses the sup-norm if
c          cgscre = 2. In adition, the precision required to CG is equal to
c          cgepsi (conjugate gradient initial epsilon) at x0 and cgepsf
c          (conjugate gradient final epsilon) when the euclidian- or sup-norm
c          of the projected gradient is equal to cggpnf (conjugate gradients
c          projected gradient final norm) which is an estimation of the value
c          of the euclidian- or sup-norm of the projected gradient at the
c          solution.
c
c          RECOMMENDED: cgscre = 1, cggpnf = epsgpen; or
c                       cgscre = 2, cggpnf = epsgpsn.
c
c     cgepsi, cgepsf double precision
c          small positive numbers for declaring convergence of the
c          conjugate gradient subalgorithm when
c          ||r||_2 < cgeps * ||rhs||_2, where r is the residual and
c          rhs is the right hand side of the linear system, i.e., cg
c          stops when the relative error of the solution is smaller
c          that cgeps.
c
c          cgeps varies from cgepsi to cgepsf in such a way that, depending
c          on cgscre (see above),
c
c          i) log10(cgeps^2) depends linearly on log10(||g_P(x)||_2^2)
c          which varies from ||g_P(x_0)||_2^2 to epsgpen^2; or
c
c          ii) log10(cgeps) depends linearly on log10(||g_P(x)||_inf)
c          which varies from ||g_P(x_0)||_inf to epsgpsn.
c
c          RECOMMENDED: cgepsi = 1.0d-1, cgepsf = 1.0d-5
c
c     epsnqmp double precision
c          see below
c
c     maxitnqmp integer
c          This and the previous one parameter are used for a stopping
c          criterion of the conjugate gradient subalgorithm. If the
c          progress in the quadratic model is less or equal than a
c          fraction of the best progress ( epsnqmp * bestprog ) during
c          maxitnqmp consecutive iterations then CG is stopped by not
c          enough progress of the quadratic model.
c
c          RECOMMENDED: epsnqmp = 1.0d-4, maxitnqmp = 5
c
c     nearlyq logical
c          if function f is (nearly) quadratic, use the option
c          nearlyq = TRUE. Otherwise, keep the default option.
c
c          if, at an iteration of CG we find a direction d such
c          that d^T H d <= 0 then we take the following decision:
c
c          (i) if nearlyq = TRUE then take direction d and try to
c          go to the boundary chosing the best point among the two
c          point at the boundary and the current point.
c
c          (ii) if nearlyq = FALSE then we stop at the current point.
c
c          RECOMMENDED: nearlyq = .FALSE.
c
c     gtype integer
c          type of gradient calculation
c          gtype = 0 means user suplied evalg subroutine,
c          gtype = 1 means central diference approximation.
c
c          RECOMMENDED: gtype = 0
c
c          (provided you have the evalg subroutine)
c
c     htvtype integer
c          type of gradient calculation
c          htvtype = 0 means user suplied evalhd subroutine,
c          htvtype = 1 means incremental quotients approximation.
c
c          RECOMMENDED: htvtype = 1
c
c          (you take some risk using this option but, unless you have
c          a good evalhd subroutine, incremental quotients is a very
c          cheap option)
c
c     trtype integer
c          type of trust-region radius
c          trtype = 0 means 2-norm trust-region
c          trtype = 1 means infinite-norm trust-region
c
c          RECOMMENDED: trtype = 0
c
c     iprint integer
c          commands printing. Nothing is printed if iprint < 0.
c          If iprint = 0, only initial and final information is printed.
c          If iprint > 0, information is printed every iprint iterations.
c          Exhaustive printing when iprint > 0 is commanded by iprint2.
c
c          RECOMMENDED: iprint = 1
c
c     iprint2 integer
c          When iprint > 0, detailed printing can be required setting
c          iprint2 = 1.
c
c          RECOMMENDED: iprint2 = 1
c
c     s,y,d,w double precision s(n),y(n),d(n),w(5*n)
c          working vectors
c
c     ind  integer ind(n)
c          working vector
c
c     eta  double precision
c          constant for deciding abandon the current face or not
c          We abandon the current face if the norm of the internal
c          gradient (here, internal components of the continuous
c          projected gradient) is smaller than (1-eta) times the
c          norm of the continuous projected gradient. Using eta=0.9
c          is a rather conservative strategy in the sense that
c          internal iterations are preferred over SPG iterations.
c
c          RECOMMENDED: eta = 0.9
c
c     delmin double precision
c          minimum ``trust region'' to compute the Truncated Newton
c          direction
c
c          RECOMMENDED: delmin = 0.1
c
c     lammin, lammax double precision
c          The spectral steplength, called lambda, is projected
c          inside the box [lammin,lammax]
c
c          RECOMMENDED: lammin = 10^{-10} and lammax = 10^{10}
c
c     theta double precision
c          constant for the angle condition, i.e., at iteration k
c          we need a direction d_k such that
c          <g_k,d_k> <= -theta ||g||_2 ||d_k||_2,
c          where g_k is \nabla f(x_k)
c
c          RECOMMENDED: theta = 10^{-6}
c
c     gamma double precision
c          constant for the Armijo crtierion
c          f(x + alpha d) <= f(x) + gamma * alpha * <\nabla f(x),d>
c
c          RECOMMENDED: gamma = 10^{-4}
c
c     beta double precision
c          constant for the beta condition
c          <d_k, g(x_k + d_k)>  .ge.  beta * <d_k,g_k>
c          if (x_k + d_k) satisfies the Armijo condition but does not
c          satisfy the beta condition then the point is accepted, but
c          if it satisfied the Armijo condition and also satisfies the
c          beta condition then we know that there is the possibility
c          for a succesful extrapolation
c
c          RECOMMENDED: beta = 0.5
c
c     sigma1, sigma2 double precision
c          constant for the safeguarded interpolation
c          if alpha_new \notin [sigma1, sigma*alpha] then we take
c          alpha_new = alpha / nint
c
c          RECOMMENDED: sigma1 = 0.1 and sigma2 = 0.9
c
c     nint double precision
c          constant for the interpolation. See the description of
c          sigma1 and sigma2 above. Sometimes we take as a new trial
c          step the previous one divided by nint
c
c          RECOMMENDED: nint = 2.0
c
c     next double precision
c          constant for the extrapolation
c          when extrapolating we try alpha_new = alpha * next
c
c          RECOMMENDED: next = 2.0
c
c     mininterp integer
c          constant for testing if, after having made at least mininterp
c          interpolations, the steplength is too small. In that case
c          failure of the line search is declared (may be the direction
c          is not a descent direction due to an error in the gradient
c          calculations)
c
c          RECOMMENDED: mininterp = 4
c
c          (use mininterp > maxfc for inhibit this stopping criterion)
c
c     ncomp integer
c          this constant is just for printing. In a detailed printing
c          option, ncomp component of the actual point will be printed
c
c          RECOMMENDED: ncomp = 5
c
c     sterel, steabs double precision
c          this constants mean a ``relative small number'' and ``an
c          absolute small number'' for the increments in finite
c          difference approximations of derivatives
c
c          RECOMMENDED: epsrel = 10^{-7}, epsabs = 10^{-10}
c
c     epsrel, epsabs, infty  double precision
c          this constants mean a ``relative small number'', ``an
c          absolute small number'', and ``infinite or a very big
c          number''. Basically, a quantity A is considered negligeble
c          with respect to another quantity B if
c          |A| < max ( epsrel * |B|, epsabs )
c
c          RECOMMENDED: epsrel = 10^{-10}, epsabs = 10^{-20} and
c          infty = 10^{+20}
c
c
c     On Return
c
c     x    double precision x(n)
c          final estimation to the solution
c
c     f    double precision
c          function value at the final estimation
c
c     g    double precision g(n)
c          gradient at the final estimation
c
c     gpeucn2 double precision
c          squared 2-norm of the continuous projected
c          gradient g_p at the final estimation (||g_p||_2^2)
c
c     gpsupn double precision
c          ||g_p||_inf at the final estimation
c
c     iter integer
c          number of iterations
c
c     fcnt integer
c          number of function evaluations
c
c     gcnt integer
c          number of gradient evaluations
c
c     cgcnt integer
c          number of conjugate gradient iterations
c
c     spgiter integer
c          number of SPG iterations
c
c     spgfcnt integer
c          number of function evaluations in SPG-directions line searches
c
c     tniter integer
c          number of Truncated Newton iterations
c
c     tnfcnt integer
c          number of function evaluations in TN-directions line searches
c
c     tnintcnt integer
c          number of times a backtracking in a TN-drection was needed
c
c     tnexgcnt integer
c          number of times an extrapolation in a TN-direction was
c          succesful in decreass the function value
c
c     tnexbcnt integer
c          number of times an extrapolation was aborted in the first
c          extrapolated point by augment of the function value
c
c     flag integer
c          This output parameter tells what happened in this
c          subroutine, according to the following conventions:
c
c          0= convergence with small euclidian-norm of the
c             projected gradient (smaller than epsgpen);
c
c          1= convergence with small infinite-norm of the
c             projected gradient (smaller than epsgpsn);
c
c          2= the algorithm stopped by ``lack of enough progress'',
c             that means that f(x_k) - f(x_{k+1}) <=
c             epsnfp * max { f(x_j)-f(x_{j+1}, j<k} during maxitnfp
c             consecutive iterations;
c
c          3= the algorithm stopped because the order of the euclidian-
c             norm of the continuous projected gradient did not change
c             during maxitngp consecutive iterations. Probably, we
c             are asking for an exagerately small norm of continuous
c             projected gradient for declaring convergence;
c
c          4= the algorithm stopped because the functional value
c             is very small (f <= fmin);
c
c          6= too small step in a line search. After having made at
c             least mininterp interpolations, the steplength becames
c             small. ``small steplength'' means that we are at point
c             x with direction d and step alpha, and
c
c             alpha * ||d||_infty < max(epsabs, epsrel * ||x||_infty).
c
c             In that case failure of the line search is declared
c             (may be the direction is not a descent direction
c             due to an error in the gradient calculations). Use
c             mininterp > maxfc for inhibit this criterion;
c
c          7= it was achieved the maximum allowed number of
c             iterations (maxit);
c
c          8= it was achieved the maximum allowed number of
c             function evaluations (maxfc);
c
c          9= error in evalf subroutine;
c
c         10= error in evalg subroutine;
c
c         11= error in evalhd subroutine.

      character*3 ittype
      logical outite,outdet,evals
      integer i,itnfp,itngp,cgflag,lsflag,nind,nprint,cgmaxit,cgiter,
     *fcntprev,tnintprev,tnexgprev,tnexbprev,rbdtype,rbdind,inform
      double precision lambda,gieucn2,gpi,fprev,sts,sty,epsgpen2,delta,
     *currprog,bestprog,gexp,gexpprev,cgeps,xnorm,ometa2,amax,amaxx,
     *acgeps,bcgeps,kappa,gpeucn20,gpsupn0

c     =======================================================
c     Initialization
c     =======================================================

c     Set some initial values:

c     counters,
      iter= 0
      fcnt= 0
      gcnt= 0
      cgcnt= 0

      spgiter= 0
      spgfcnt= 0

      tniter= 0
      tnfcnt= 0

      tnstpcnt= 0
      tnintcnt= 0
      tnexgcnt= 0
      tnexbcnt= 0

      tnintfe= 0
      tnexgfe= 0
      tnexbfe= 0

c     just for printing,
      nprint= min0(n,ncomp)

c     for testing convergence,
      epsgpen2= epsgpen**2

c     for testing wether abandon the current face or not,
c     (ometa2 means '(one minus eta) squared')
      ometa2= (1.0d0-eta)**2

c     for testing progress in f,
      fprev= infty
      bestprog= 0.0d0
      itnfp= 0

c     for testing progress in the order of the gradient norm, and
      gexpprev= infty
      itngp= 0

c     Print problem information

      if(iprint.ge.0) then
          write(*,977) n
          write(*,978) nprint,(l(i),i=1,nprint)
          write(*,979) nprint,(u(i),i=1,nprint)
          write(*,980) nprint,(x(i),i=1,nprint)

          write(10,977) n
          write(10,978) nprint,(l(i),i=1,nprint)
          write(10,979) nprint,(u(i),i=1,nprint)
          write(10,980) nprint,(x(i),i=1,nprint)
      end if

c     Project initial guess. If the initial guess is infeasible,
c     projection puts it in the box.

      do i= 1, n
          x(i)= dmax1(l(i),dmin1(x(i),u(i)))
      end do

c     Compute x euclidian-norm

      xnorm= 0.0d0
      do i= 1, n
          xnorm= xnorm + x(i)**2
      end do
      xnorm= dsqrt(xnorm)

c     Compute function and gradient at the initial point

      call evalf(n,x,f,inform)
      fcnt= fcnt + 1

      if (inform.ne.0) then
          flag = 9

          if (iprint.ge.0) then
              write(*,999)  flag
              write(10,999) flag
          end if

          go to 500
      end if

c      if (evals(n,x,f,inform)) then
c          flag = 0
c          go to 500
c      end if

      if (gtype.eq.0) then
          call evalg(n,x,g,inform)
      else if (gtype.eq.1) then
          call evalgdiff(n,x,g,sterel,steabs,evalf,inform)
      end if
      gcnt= gcnt + 1

      if (inform.ne.0) then
          flag = 10

          if (iprint.ge.0) then
              write(*,1000)  flag
              write(10,1000) flag
          end if

          go to 500
      end if

c     Compute continuous project gradient infinite- and euclidian-
c     norm, internal gradient euclidian-norm, and store in nind the
c     number of free variables and in array p their identifiers.

      nind= 0
      gpsupn= 0.0d0
      gpeucn2= 0.0d0
      gieucn2= 0.0d0
      do i= 1, n
          gpi= dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i)
          gpsupn= dmax1(gpsupn, dabs(gpi))
          gpeucn2= gpeucn2 + gpi**2
          if (x(i).gt.l(i).and.x(i).lt.u(i)) then
              gieucn2= gieucn2 + gpi**2
              nind= nind + 1
              ind(nind)= i
          end if
      end do

c     Compute a linear relation between gpeucn2 and cgeps2, i.e.,
c     scalars a and b such that
c
c         a * log10(||g_P(x_0)||_2^2) + b = log10(cgeps_0^2) and
c
c         a * log10(||g_P(x_f)||_2^2) + b = log10(cgeps_f^2),
c
c     where cgeps_0 and cgeps_f are provided. Note that if
c     cgeps_0 is equal to cgeps_f then cgeps will be allways
c     equal to cgeps_0 and cgeps_f.

c     We introduce now a linear relation between gpsupn and cgeps also.

      if (cgscre.eq.1) then
          acgeps= 2.0d0*dlog10(cgepsf/cgepsi)/dlog10(cggpnf**2/gpeucn2)
          bcgeps= 2.0d0*dlog10(cgepsi)-acgeps*dlog10(gpeucn2)
      else ! if (cgscre.eq.2) then
          acgeps= dlog10(cgepsf/cgepsi)/dlog10(cggpnf/gpsupn)
          bcgeps= dlog10(cgepsi)-acgeps*dlog10(gpsupn)
      end if

c     And it will be used for the linear relation of cgmaxit

      gpsupn0= gpsupn
      gpeucn20= gpeucn2

c     Print initial information

      if(iprint.ge.0) then
          write(*,981) iter
          write(*,985) nprint,(x(i),i=1,nprint)
          write(*,986) nprint,(g(i),i=1,nprint)
          write(*,987) nprint,
     *    (dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i),i=1,nprint)
          write(*,988) min0(nprint,nind),nind,
     *    (ind(i),i=1,min0(nprint,nind))
          write(*,1003) f,dsqrt(gpeucn2),dsqrt(gieucn2),gpsupn,nind,n,
     *    spgiter,tniter,fcnt,gcnt,cgcnt

          write(10,981) iter
          write(10,985) nprint,(x(i),i=1,nprint)
          write(10,986) nprint,(g(i),i=1,nprint)
          write(10,987) nprint,
     *    (dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i),i=1,nprint)
          write(10,988) min0(nprint,nind),nind,
     *    (ind(i),i=1,min0(nprint,nind))
          write(10,1003) f,dsqrt(gpeucn2),dsqrt(gieucn2),gpsupn,nind,n,
     *    spgiter,tniter,fcnt,gcnt,cgcnt
      end if

c     Test whether the initial functional value is very small

      if (f.le.fmin) then
          flag= 4

          if (iprint.ge.0) then
              write(*,994)  flag,fmin
              write(10,994) flag,fmin
          end if

          go to 500
      end if

c     Test whether the number of functional evaluations is
c     exhausted (i.e., maxfc = 1)

      if (fcnt.ge.maxfc) then
          flag= 8

          if (iprint.ge.0) then
              write(*,998)  flag,maxfc
              write(10,998) flag,maxfc
          end if

          go to 500
      end if

c     =======================================================
c     Main loop
c     =======================================================

 100  continue

c     =======================================================
c     Test stopping criteria
c     =======================================================

c     Test whether the continuous projected gradient euclidian-norm
c     is small enough to declare convergence

      if (gpeucn2.le.epsgpen2) then
          flag= 0

          if (iprint.ge.0) then
              write(*,990)  flag,epsgpen
              write(10,990) flag,epsgpen
          end if

          go to 500
      end if

c     Test whether the continuous projected gradient infinite-norm
c     is small enough to declare convergence

      if (gpsupn.le.epsgpsn) then
          flag= 1

          if (iprint.ge.0) then
              write(*,991)  flag,epsgpsn
              write(10,991) flag,epsgpsn
          end if

          go to 500
      end if

c     Test whether we performed many iterations without good progress
c     of the functional value

      currprog= fprev - f
      bestprog= dmax1(currprog, bestprog)

      if (currprog.le.epsnfp*bestprog) then

          itnfp= itnfp + 1

          if (itnfp.ge.maxitnfp) then
              flag= 2

              if (iprint.ge.0) then
                  write(*,992)  flag,epsnfp,maxitnfp
                  write(10,992) flag,epsnfp,maxitnfp
              end if

              go to 500
          endif

      else
          itnfp= 0
      endif

c     Test whether we have performed many iterations without good
c     reduction of the euclidian-norm of the projected gradient

      gexp= dlog10(gpeucn2)

      if (gexp.ge.gexpprev) then

          itngp= itngp + 1

          if(itngp.ge.maxitngp) then
              flag= 3

              if (iprint.ge.0) then
                  write(*,993)  flag,maxitngp
                  write(10,993) flag,maxitngp
              end if

              go to 500
          endif

      else
          itngp= 0
      endif

      gexpprev= gexp

c     Test whether the number of iterations is exhausted

      if (iter.ge.maxit) then
          flag= 7

          if (iprint.ge.0) then
              write(*,997)  flag,maxit
              write(10,997) flag,maxit
          end if

          go to 500
      end if

c     Note that the stopping criteria related to small functional
c     values ( f <= fmin ) and number of functional evaluations
c     are detected inside the line searches and do not need to
c     be tested here

c     =======================================================
c     The stopping criteria were not satisfied, a new
c     iteration will be made
c     =======================================================

      iter= iter + 1

c     =======================================================
c     Will we print information on this iteration?
c     Detailed or not?
c     =======================================================

      if (iprint.gt.0.and.mod(iter,iprint).eq.0) then
          outite= .true.
          if (iprint2.eq.1) then
              outdet= .true.
          else
	      outdet= .false.
          end if
      else
          outite= .false.
          outdet= .false.
      end if

c     =======================================================
c     Save current values, f, x and g
c     =======================================================

      fprev= f

      do i= 1, n
          s(i)= x(i)
          y(i)= g(i)
      end do

c     =======================================================
c     Compute new iterate
c     =======================================================

c     We abandon the current face if the norm of the internal gradient
c     (here, internal components of the continuous projected gradient)
c     is smaller than (1-eta) times the norm of the continuous projected
c     gradient. Using eta=0.9 is a rather conservative strategy in the
c     sense that internal iterations are preferred over SPG iterations.
c     Replace eta=0.9 by other tolerance in (0,1) if you find it convenient.

      if (gieucn2.le.ometa2*gpeucn2) then

c         ===================================================
c         Some constraints should be abandoned. Compute
c         the new iterate using an SPG iteration
c         ===================================================

          ittype= 'SPG'
          spgiter= spgiter + 1

c         Compute spectral steplength

          if (iter.eq.1.or.sty.le.0.0d0) then
              lambda= dmax1(1.0d0,xnorm)/dsqrt(gpeucn2)
          else
              lambda= sts/sty
          end if
          lambda= dmin1(lammax,dmax1(lammin,lambda))

c         Perform a line search with safeguarded quadratic
c         interpolation along the direction of the spectral
c         continuous projected gradient

          fcntprev= fcnt
          call spgls(n,x,f,g,l,u,lambda,fmin,maxfc,outdet,fcnt,lsflag,
     *    w(1),w(n+1),gamma,sigma1,sigma2,nint,mininterp,sterel,steabs,
     *    epsrel,epsabs,infty,evalf)

          spgfcnt= spgfcnt + (fcnt-fcntprev)

          if (lsflag.eq.9) then
              flag = 9

              if (iprint.ge.0) then
                  write(*,999)  flag
                  write(10,999) flag
              end if

              go to 500
          end if

c         Compute the gradient of the new iterate

          if (gtype.eq.0) then
              call evalg(n,x,g,inform)
          else if (gtype.eq.1) then
              call evalgdiff(n,x,g,sterel,steabs,evalf,inform)
          end if
          gcnt= gcnt + 1

          if (inform.ne.0) then
              flag = 10

              if (iprint.ge.0) then
                  write(*,1000)  flag
                  write(10,1000) flag
              end if

              go to 500
          end if

      else

c         ===================================================
c         The new iterate will belong to the closure of
c         the actual face
c         ===================================================

          ittype= 'TN '
          tniter= tniter + 1

c         Compute trust-region radius

          if (iter.eq.1) then
              if(udelta0.lt.0.d0) then
                  delta= dmax1(delmin,100.0d0*dmax1(1.0d0,xnorm))
              else
                  delta= udelta0
              end if
          else
              delta= dmax1(delmin,10.0d0*dsqrt(sts))
          end if

c         Shrink the point, its gradient and the bounds

          call shrink(nind,ind,n,x,g,l,u)

c         Compute the descent direction solving the newtonian
c         system by conjugate gradients

c         Set conjugate gradient stopping criteria. Default values are
c         taken if you set ucgeps < 0 and ucgmaxit < 0, respectively.
c         Otherwise, the parameters cgeps and cgmaxit will be the ones
c         set by the user.

          if(ucgmaxit.lt.0) then
              if (nearlyq) then
                  cgmaxit= nind
              else
                  if (cgscre.eq.1) then
                      kappa= dlog10(gpeucn2/gpeucn20)/
     *                       dlog10(epsgpen2/gpeucn20)
                  else ! if (cgscre.eq.2) then
                      kappa= dlog10(gpsupn/gpsupn0)/
     *                       dlog10(epsgpsn/gpsupn0)
                  end if
                  kappa= dmax1(0.0d0,dmin1(1.0d0,kappa))
                  cgmaxit= int(
     *            (1.0d0-kappa)*dmax1(1.0d0,10.0d0*dlog10(dfloat(nind)))
     *            + kappa*dfloat(nind) )
              end if
          else
              cgmaxit= ucgmaxit
          end if

          if (cgscre.eq.1) then
              cgeps= dsqrt(10.0d0**(acgeps*dlog10(gpeucn2)+bcgeps))
          else ! if (cgscre.eq.2) then
              cgeps= 10.0d0**(acgeps*dlog10(gpsupn)+bcgeps)
          end if
          cgeps= dmax1(cgepsf,dmin1(cgepsi,cgeps))

c         Call conjugate gradients

          call cg(nind,ind,n,x,g,delta,l,u,cgeps,epsnqmp,maxitnqmp,
     *    cgmaxit,nearlyq,gtype,htvtype,trtype,outdet,ncomp,d,cgiter,
     *    rbdtype,rbdind,cgflag,w(1),w(n+1),w(2*n+1),w(3*n+1),w(4*n+1),
     *    theta,sterel,steabs,epsrel,epsabs,infty,evalf,evalg,evalhd)

	  cgcnt= cgcnt + cgiter

          if (cgflag.eq.10) then
              flag = 10

              if (iprint.ge.0) then
                  write(*,1000)  flag
                  write(10,1000) flag
              end if

              go to 500

          else if (cgflag.eq.11) then
              flag = 11

              if (iprint.ge.0) then
                  write(*,1001)  flag
                  write(10,1001) flag
              end if

              go to 500
          end if

c         Compute maximum step

          if (cgflag.eq.2) then
              amax= 1.0d0
          else
              amax= infty
              do i= 1, nind
                  if (d(i).gt.0.0d0.and.u(i).lt.infty) then
                      amaxx= (u(i)-x(i))/d(i)
                      if (amaxx.lt.amax) then
                          amax= amaxx
                          rbdind= i
                          rbdtype= 2
                      end if
                  else if (d(i).lt.0.0d0.and.l(i).gt.-infty) then
                      amaxx= (l(i)-x(i))/d(i)
                      if (amaxx.lt.amax) then
                          amax= amaxx
                          rbdind= i
                          rbdtype= 1
                      end if
                  end if
               end do
          end if

c         Perform the line search

          tnintprev= tnintcnt
          tnexgprev= tnexgcnt
          tnexbprev= tnexbcnt

          fcntprev= fcnt

          call tnls(nind,ind,n,x,f,g,d,l,u,amax,rbdtype,rbdind,fmin,
     *    maxfc,gtype,outdet,fcnt,gcnt,tnintcnt,tnexgcnt,tnexbcnt,
     *    lsflag,w(1),w(n+1),gamma,beta,sigma1,sigma2,nint,next,
     *    mininterp,sterel,steabs,epsrel,epsabs,infty,evalf,evalg)

          if (lsflag.eq.9) then
              flag = 9

              if (iprint.ge.0) then
                  write(*,999)  flag
                  write(10,999) flag
              end if

              go to 500

          else if (lsflag.eq.10) then
              flag = 10

              if (iprint.ge.0) then
                  write(*,1000)  flag
                  write(10,1000) flag
              end if

              go to 500
          end if

          tnfcnt= tnfcnt + (fcnt-fcntprev)

          if (tnintcnt.gt.tnintprev) then
              tnintfe= tnintfe + (fcnt-fcntprev)
          else if (tnexgcnt.gt.tnexgprev) then
              tnexgfe= tnexgfe + (fcnt-fcntprev)
          else if (tnexbcnt.gt.tnexbprev) then
              tnexbfe= tnexbfe + (fcnt-fcntprev)
          else
              tnstpcnt= tnstpcnt + 1
          end if

c         Expand the point, its gradient and the bounds

          call expand(nind,ind,n,x,g,l,u)

c         If the line search (interpolation) in the Truncated Newton
c         direction stopped due to a very small step (lsflag=6) we
c         will discard this iteration and force a SPG iteration

c         Note that tnls subroutine was coded in such a way that in
c         case of lsflag=6 termination the subroutine discards all
c         what was made and returns with the same point it started

          if (lsflag.eq.6) then

              if (outdet) then
                  write(*,*)
                  write(*,*)
     *            '     The previous NT iteration was discarded due to',
     *            '     a termination for very small step in the line ',
     *            '     search. A SPG iteration will be forced now.   '

                  write(10,*)
                  write(10,*)
     *            '     The previous NT iteration was discarded due to',
     *            '     a termination for very small step in the line ',
     *            '     search. A SPG iteration will be forced now.   '
              end if

              ittype= 'SPG'
              spgiter= spgiter + 1

c             Compute spectral steplength

              if (iter.eq.1.or.sty.le.0.0d0) then
                  lambda= dmax1(1.0d0,xnorm)/dsqrt(gpeucn2)
              else
                  lambda= sts/sty
              end if
              lambda= dmin1(lammax,dmax1(lammin,lambda))

c             Perform a line search with safeguarded quadratic
c             interpolation along the direction of the spectral
c             continuous projected gradient

              fcntprev= fcnt

              call spgls(n,x,f,g,l,u,lambda,fmin,maxfc,outdet,fcnt,
     *        lsflag,w(1),w(n+1),gamma,sigma1,sigma2,nint,mininterp,
     *        sterel,steabs,epsrel,epsabs,infty,evalf)

              spgfcnt= spgfcnt + (fcnt-fcntprev)

              if (lsflag.eq.9) then
                  flag = 9

                  if (iprint.ge.0) then
                      write(*,999)  flag
                      write(10,999) flag
                  end if

                  go to 500
              end if

c             Compute the gradient in the new iterate

              if (gtype.eq.0) then
                  call evalg(n,x,g,inform)
              else if (gtype.eq.1) then
                  call evalgdiff(n,x,g,sterel,steabs,evalf,inform)
              end if
              gcnt= gcnt + 1

              if (inform.ne.0) then
                  flag = 10

                  if (iprint.ge.0) then
                      write(*,1000)  flag
                      write(10,1000) flag
                  end if

                  go to 500
              end if

          end if

      end if

c     =======================================================
c     Prepare for the next iteration
c     =======================================================

c     This adjustment/projection is "por lo que las putas pudiera"

      do i= 1, n
          if (x(i).le.l(i)+dmax1(epsrel*dabs(l(i)),epsabs)) then
              x(i)= l(i)
          else if (x(i).ge.u(i)-dmax1(epsrel*dabs(u(i)),epsabs)) then
              x(i)= u(i)
          end if
      end do

c     Compute x euclidian-norm

      xnorm= 0.0d0
      do i= 1, n
          xnorm= xnorm + x(i)**2
      end do
      xnorm= dsqrt(xnorm)

c     Compute s = x_{k+1} - x_k, y = g_{k+1} - g_k, <s,s> and <s,y>

      sts= 0.0d0
      sty= 0.0d0
      do i= 1, n
          s(i)= x(i)-s(i)
          y(i)= g(i)-y(i)
          sts= sts + s(i)*s(i)
          sty= sty + s(i)*y(i)
      end do

c     Compute continuous project gradient infinite- and euclidian-
c     norm, internal gradient euclidian-norm, and store in nind the
c     number of free variables and in array p its identifiers.

      nind= 0
      gpsupn= 0.0d0
      gpeucn2= 0.0d0
      gieucn2= 0.0d0
      do i= 1, n
          gpi= dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i)
          gpsupn= dmax1(gpsupn, dabs(gpi))
          gpeucn2= gpeucn2 + gpi**2
          if (x(i).gt.l(i).and.x(i).lt.u(i)) then
              gieucn2= gieucn2 + gpi**2
              nind= nind + 1
              ind(nind)= i
          end if
      end do

c     Print information of this iteration

      if (outite) then
          if (outdet) then
		write(*,983) iter,ittype
	  	write(*,985) nprint,(x(i),i=1,nprint)
          	write(*,986) nprint,(g(i),i=1,nprint)
          	write(*,987) nprint,
     *    	(dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i),i=1,nprint)
          	write(*,988) min0(nprint,nind),nind,
     *    	(ind(i),i=1,min0(nprint,nind))
	        write(*,1003) f,dsqrt(gpeucn2),dsqrt(gieucn2),gpsupn,
     *    	nind,n,spgiter,tniter,fcnt,gcnt,cgcnt
	  else
		write(*,1002)iter,f,dsqrt(gieucn2),dsqrt(gpeucn2),gpsupn
          endif

          if (outdet) then
		write(10,983) iter,ittype
          	write(10,985) nprint,(x(i),i=1,nprint)
          	write(10,986) nprint,(g(i),i=1,nprint)
          	write(10,987) nprint,
     *    	(dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i),i=1,nprint)
          	write(10,988) min0(nprint,nind),nind,
     *    	(ind(i),i=1,min0(nprint,nind))
	        write(10,1003) f,dsqrt(gpeucn2),dsqrt(gieucn2),gpsupn,
     *    	nind,n,spgiter,tniter,fcnt,gcnt,cgcnt
	  else
		write(10,1002)iter,f,dsqrt(gieucn2),dsqrt(gpeucn2),
     *		gpsupn
	  endif
      end if

c     =======================================================
c     Test some stopping criteria that may occur inside the
c     line searches
c     =======================================================

      if (lsflag.eq.4) then

          flag= 4

          if (iprint.ge.0) then
              write(*,994)  flag,fmin
              write(10,994) flag,fmin
          end if

          go to 500

      else if (lsflag.eq.6) then

          flag= 6

          if (iprint.ge.0) then
              write(*,996)  flag,mininterp,epsrel,epsabs
              write(10,996) flag,mininterp,epsrel,epsabs
          end if

          go to 500

      else if (lsflag.eq.8) then

          flag= 8

          if (iprint.ge.0) then
              write(*,998)  flag,maxfc
              write(10,998) flag,maxfc
          end if

          go to 500

      end if

c     =======================================================
c     Iterate
c     =======================================================

c      if (evals(n,x,f,inform)) then
c          flag = 0
c          go to 500
c      end if
c
      go to 100

c     =======================================================
c     End of main loop
c     =======================================================

c     =======================================================
c     Report output status and return
c     =======================================================

 500  continue

c     Print final information

      if (iprint.ge.0) then

          write(*,982) iter
          write(*,985) nprint,(x(i),i=1,nprint)
          write(*,986) nprint,(g(i),i=1,nprint)
          write(*,987) nprint,
     *    (dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i),i=1,nprint)
          write(*,988) min0(nprint,nind),nind,
     *    (ind(i),i=1,min0(nprint,nind))
          write(*,1003) f,dsqrt(gpeucn2),dsqrt(gieucn2),gpsupn,nind,n,
     *    spgiter,tniter,fcnt,gcnt,cgcnt

          write(10,982) iter
          write(10,985) nprint,(x(i),i=1,nprint)
          write(10,986) nprint,(g(i),i=1,nprint)
          write(10,987) nprint,
     *    (dmin1(u(i),dmax1(l(i),x(i)-g(i)))-x(i),i=1,nprint)
          write(10,988) min0(nprint,nind),nind,
     *    (ind(i),i=1,min0(nprint,nind))
          write(10,1003) f,dsqrt(gpeucn2),dsqrt(gieucn2),gpsupn,nind,n,
     *    spgiter,tniter,fcnt,gcnt,cgcnt

      end if

      return

c     Non-executable statements

 977  format(/1X, 'Entry to GENCAN. Number of variables: ',I7)
 978  format(/1X,'Lower bounds (first ',I6, ' components): ',
     */,6(1X,1PD11.4))
 979  format(/1X,'Upper bounds (first ',I6, ' components): ',
     */,6(1X,1PD11.4))
 980  format(/1X,'Initial point (first ',I6, ' components): ',
     */,6(1X,1PD11.4))
 981  format(/1X,'GENCAN iteration: ',I6, ' (Initial point)')
 982  format(/1X,'GENCAN iteration: ',I6, ' (Final point)')
 983  format(/,1X,'GENCAN iteration: ',I6,
     *' (This point was obtained using a ',A3,' iteration)')
 985  format(1X,'Current point (first ',I6, ' components): ',
     */,6(1X,1PD11.4))
 986  format(1X,'Current gradient (first ',I6, ' components): ',
     */,6(1X,1PD11.4))
 987  format(1X,'Current continuous projected gradient (first ',I6,
     *' components): ',/,6(1X,1PD11.4))
 988  format(1X,'Current free variables (first ',I6,
     *', the number of free variables is ',I6,'): ',/,10(1X,I6))
 990  format(/1X,'Flag of GENCAN= ',I2,
     *' (convergence with Euclidian-norm of the projected gradient',
     */,1X,'smaller than ',1PD11.4,')')
 991  format(/1X,'Flag of GENCAN= ',I2,
     *' (convergence with sup-norm of the projected gradient smaller',
     */,1X,'than ',1PD11.4,')')
 992  format(/1X,'Flag of GENCAN= ',I2,
     *' (The algorithm stopped by lack of enough progress. This means',
     */,1X,'that  f(x_k) - f(x_{k+1}) .le. ',1PD11.4,
     *' * max [ f(x_j)-f(x_{j+1}, j < k ]',/,1X,'during ',I7,
     *' consecutive iterations')
 993  format(/1X,'Flag of GENCAN= ',I2,
     *' (The algorithm stopped because the order of the',
     */,1X,'Euclidian-norm of the continuous projected gradient did',
     *' not change during ',/,1X,I7,' consecutive iterations.',
     *' Probably, an exagerately small norm of the',/,1X,'continuous',
     *' projected gradient is required for declaring convergence')
 994  format(/1X,'Flag of GENCAN= ',I2,
     *' (The algorithm stopped because the functional value is',
     */,1X,'smaller than ',1PD11.4)
 996  format(/1X,'Flag of GENCAN= ',I2,
     *' (Too small step in a line search. After having made at least ',
     */,1X,I7,' interpolations, the steplength becames small. Small',
     *' means that we were',/,1X,'at point x with direction d and took',
     *' a step  alpha such that',/,1X,'alpha * |d_i| .lt. max [',
     *1PD11.4,' * |x_i|,',1PD11.4,' ] for all i')
 997  format(/1X,'Flag of GENCAN= ',I2,
     *' (It was exceeded the maximum allowed number of iterations',
     */,1X,'(maxit=',I7,')')
 998  format(/1X,'Flag of GENCAN= ',I2,
     *' (It was exceeded the maximum allowed number of functional',
     */,1X,'evaluations (maxfc=',I7,')')
 999  format(/1X,'Flag of GENCAN= ',I2,
     *' (Error in evalf subroutine)')
 1000 format(/1X,'Flag of GENCAN= ',I2,
     *' (Error in evalg subroutine)')
 1001 format(/1X,'Flag of GENCAN= ',I2,
     *' (Error in evalhd subroutine)')
 1002 format(/I5,1X,'f= ',1PD11.4,2X,'|ipg|2= ',1PD11.4,2X,'|pg|2= ',
     *1PD11.4,2X,'|pg|sup= ',1PD11.4)
 1003 format(1X,'Functional value: ', 1PD11.4,
     */,1X,'Euclidian norm of the continuous projected gradient: ',
     *1PD11.4,
     */,1X,'Euclidian norm of the internal projection of gp: ',1PD11.4,
     */,1X,'Sup-norm of the continuous projected gradient: ',1PD11.4,
     */,1X,'Free variables at this point: ',I7,
     *' (over a total of ',I7,')',
     */,1X,'SPG iterations: ',I7,
     */,1X,'TN iterations: ',I7,
     */,1X,'Functional evaluations: ',I7,
     */,1X,'Gradient evaluations: ',I7,
     */,1X,'Conjugate gradient iterations: ',I7)

      end


c     ******************************************************
c     ******************************************************
      subroutine spgls(n,x,f,g,l,u,lambda,fmin,maxfc,output,fcnt,flag,
     *xtrial,d,gamma,sigma1,sigma2,nint,mininterp,sterel,steabs,epsrel,
     *epsabs,infty,evalf)

      logical output
      integer n,maxfc,fcnt,flag,mininterp
      double precision x(n),f,g(n),l(n),u(n),lambda,fmin,xtrial(n),d(n),
     *gamma,sigma1,sigma2,nint,sterel,steabs,epsrel,epsabs,infty
      external evalf
c     Safeguarded quadratic interpolation, used in SPG.
c
c     On Entry
c
c     n    integer
c          the order of the x
c
c     x    double precision x(n)
c          current point
c
c     f    double precision
c          function value at the current point
c
c     g    double precision g(n)
c          gradient vector at the current point
c
c     l    double precision l(n)
c          lower bounds
c
c     u    double precision u(n)
c          upper bounds
c
c     lambda double precision
c          spectral steplength
c
c     fmin double precision
c          functional value for the stopping criteria f <= fmin
c
c     maxfc integer
c          maximum number of funtion evaluations
c
c     output logical
c          TRUE: print some information at each iteration,
c          FALSE: no print.
c
c     xtrial, d double precision xtrial(n), d(n)
c          working vectors
c
c     gamma double precision
c          constant for the Armijo crtierion
c          f(x + alpha d) <= f(x) + gamma * alpha * <\nabla f(x),d>
c
c          RECOMMENDED: gamma = 10^{-4}
c
c     sigma1, sigma2 double precision
c          constant for the safeguarded interpolation
c          if alpha_new \notin [sigma1, sigma*alpha] then we take
c          alpha_new = alpha / nint
c
c          RECOMMENDED: sigma1 = 0.1 and sigma2 = 0.9
c
c     nint double precision
c          constant for the interpolation. See the description of
c          sigma1 and sigma2 above. Sometimes we take as a new trial
c          step the previous one divided by nint
c
c          RECOMMENDED: nint = 2.0
c
c     mininterp integer
c          constant for testing if, after having made at least mininterp
c          interpolations, the steplength is soo small. In that case
c          failure of the line search is declared (may be the direction
c          is not a descent direction due to an error in the gradient
c          calculations)
c
c          RECOMMENDED: mininterp = 4
c
c     sterel, steabs double precision
c          this constants mean a ``relative small number'' and ``an
c          absolute small number'' for the increments in finite
c          difference approximations of derivatives
c
c          RECOMMENDED: epsrel = 10^{-7}, epsabs = 10^{-10}
c
c     epsrel, epsabs, infty  double precision
c          this constants mean a ``relative small number'', ``an
c          absolute small number'', and ``infinite or a very big
c          number''. Basically, a quantity A is considered negligeble
c          with respect to another quantity B if
c          |A| < max ( epsrel * |B|, epsabs )
c
c          RECOMMENDED: epsrel = 10^{-10}, epsabs = 10^{-20} and
c          infty = 10^{+20}
c
c     On Return
c
c     x    double precision
c          final estimation of the solution
c
c     f    double precision
c          functional value at the final estimation
c
c     fcnt integer
c          number of function evaluations used in the line search
c
c     flag integer
c          This output parameter tells what happened in this
c          subroutine, according to the following conventions:
c
c          0= convergence with an Armijo-like criterion
c             (f(xnew) <= f(x) + 1.0d-4 * alpha * <g,d>);
c
c          4= the algorithm stopped because the functional value
c             is very small (f <= fmin);
c
c          6= too small step in the line search. After having made at
c             least mininterp interpolations, the steplength becames
c             small. ``small steplength'' means that we are at point
c             x with direction d and step alpha, and, for all i,
c
c             |alpha * d(i)| .le. max ( epsrel * |x(i)|, epsabs ).
c
c             In that case failure of the line search is declared
c             (maybe the direction is not a descent direction
c             due to an error in the gradient calculations). Use
c             mininterp > maxfc for inhibit this criterion;
c
c          8= it was achieved the maximum allowed number of
c             function evaluations (maxfc);
c
c          9= error in evalf subroutine.

c     We use the Armijo parameter gamma=1.0d-4. You can replace it by
c     some other number in (0,1) if you find it convenient.

      logical samep
      integer i,interp,inform
      double precision ftrial,gtd,alpha,atemp

c     Initialization

      interp= 0

c     Compute first trial point, spectral projected gradient
c     direction, and directional derivative <g,d>.

      alpha= 1.0d0

      gtd= 0.0d0
      do i= 1, n
          xtrial(i)= dmin1(u(i),dmax1(l(i),x(i)-lambda*g(i)))
          d(i)= xtrial(i)-x(i)
          gtd= gtd + g(i)*d(i)
      end do

      call evalf(n,xtrial,ftrial,inform)
      fcnt= fcnt + 1

      if (inform.ne.0) then

          flag = 9

          if (output) then
              write(*,1000) flag
              write(10,1000) flag
          end if

          go to 500

      end if

c     Print initial information

      if (output) then
          write(*,980) lambda
          write(*,999) alpha,ftrial,fcnt

          write(10,980) lambda
          write(10,999) alpha, ftrial, fcnt
      end if

c     Main loop

 100  continue

c     Test Armijo stopping criterion

      if (ftrial.le.f+gamma*alpha*gtd) then

          f= ftrial

          do i= 1, n
              x(i)= xtrial(i)
          end do

          flag= 0

          if (output) then
              write(*,990) flag
              write(10,990) flag
          end if

          go to 500

      end if

c     Test whether f is very small

      if (ftrial.le.fmin) then

          f= ftrial

          do i= 1, n
              x(i)= xtrial(i)
          end do

          flag= 4

          if (output) then
              write(*,994) flag
              write(10,994) flag
          end if

          go to 500

      end if

c     Test whether the number of functional evaluations is exhausted

      if (fcnt.ge.maxfc) then

          if (ftrial.lt.f) then

              f= ftrial

              do i= 1, n
                  x(i)= xtrial(i)
              end do

          end if

          flag= 8

          if (output) then
              write(*,998) flag
              write(10,998) flag
          end if

          go to 500

      end if

c     Compute new step (safeguarded quadratic interpolation)

      interp= interp + 1

      if (alpha.lt.sigma1) then
          alpha= alpha/nint

      else
          atemp= (-gtd*alpha**2)/(2.0d0*(ftrial-f-alpha*gtd))

          if (atemp.lt.sigma1 .or. atemp.gt.sigma2*alpha) then
              alpha= alpha/nint

          else
              alpha= atemp
          end if
      end if

c     Compute new trial point

      do i= 1, n
          xtrial(i)= x(i) + alpha*d(i)
      end do

      call evalf(n,xtrial,ftrial,inform)
      fcnt= fcnt + 1

      if (inform.ne.0) then

          flag = 9

          if (output) then
              write(*,1000) flag
              write(10,1000) flag
          end if

          go to 500

      end if

c     Print information of this iteration

      if (output) then
          write(*,999)  alpha,ftrial,fcnt
          write(10,999) alpha,ftrial,fcnt
      end if

c     Test whether at least mininterp interpolations were made and
c     two consecutive iterates are close enough

      samep= .true.
      do i= 1, n
         if (dabs(alpha*d(i)).gt.dmax1(epsrel*dabs(x(i)),epsabs)) then
             samep= .false.
         end if
      end do

      if (interp.gt.mininterp.and.samep) then

          if (ftrial.lt.f) then

              f= ftrial

              do i= 1, n
                  x(i)= xtrial(i)
              end do

          end if

          flag= 6

          if (output) then
              write(*,996)  flag
              write(10,996) flag
          end if

          go to 500

      end if

c     Iterate

      go to 100

c     Return

 500  continue

      return

c     Non-executable statements

 980  format(/,6x,'SPG (spectral steplength ',1PD11.4,')',
     */,/,6x,'SPG Line search')
 999  format(6x,'Alpha= ',1PD11.4,' F= ',1PD11.4,' FE= ',I5)
 990  format(6x,'Flag of SPG Line search= ',I2,
     *' (Convergence with an Armijo-like criterion)')
 994  format(6x,'Flag of SPG Line search= ',I2,
     *' (Small functional value, smaller than parameter fmin)')
 996  format(6x,'Flag of SPG Line search= ',I2,
     *' (Too small step in the interpolation process)')
 998  format(6x,'Flag of SPG Line search= ',I2,
     *' (Too many functional evaluations)')
 1000 format(6x,'Flag of SPG Line search= ',I2,
     *' (Error in evalf subroutine)')

      end


c     ******************************************************
c     ******************************************************
      subroutine cg(nind,ind,n,x,g,delta,l,u,eps,epsnqmp,maxitnqmp,
     *maxit,nearlyq,gtype,htvtype,trtype,output,ncomp,s,iter,rbdtype,
     *rbdind,flag,w,y,r,d,sprev,theta,sterel,steabs,epsrel,epsabs,infty,
     *evalf,evalg,evalhd)

      logical nearlyq,output
      integer nind,ind(nind),n,maxitnqmp,maxit,gtype,htvtype,trtype,
     *ncomp,iter,rbdtype,rbdind,flag
      double precision x(n),g(n),delta,l(n),u(n),eps,epsnqmp,s(n),w(n),
     *y(n),r(n),d(n),sprev(n),theta,sterel,steabs,epsrel,epsabs,infty
      external evalf,evalg,evalhd
c     This subrotuine implements the conjugate-gradient method for
c     minimizing the quadratic approximation q(s) of f(x) at x, where
c
c     q(s) = 1/2 s^T H s + g^T s,
c
c        H = \nabla^2 f(x),
c
c        g = \nabla f(x),
c
c     subject to ||s||_2 <= delta and l <= x + s <= u.
c
c     The method returns an approximation s to the solution such
c     that ||H s + g||_2 <= eps * ||g||_2; or converges to the
c     boundary of ||s||_2 <= delta and l <= x + s <= u; or finds
c     a point s and a direction d such that q(s + alpha d) = q(s)
c     for any alpha, i.e., d^T H d = g^T d = 0.
c
c     On Entry
c
c     nind integer
c          number of free variables (this is thee dimension in
c          which this subroutine will work)
c
c     ind  integer ind(n)
c          array which contains, in the first nind positions, the
c          identifiers of the free variables
c
c     n    integer
c          dimension of the full space
c
c     x    double precision x(n)
c          point at which f function is being approximated by the
c          quadratic model
c
c          The first nind positions of x contains the free variables
c          x_ind(1), x_ind(2), ..., x_ind(nind).
c
c     g    double precision g(n)
c          linear coeficient of the quadratic function
c
c          This is \nabla f(x) and it also contains in the first nind
c          positions the components g_ind(1), g_ind(2), ..., g_ind(nind).
c
c          IMPORTANT: the linear algebra of this subroutine lies in
c          a space of dimension nind. The value of the full dimension n,
c          the non-free variables (which are at the end of array x) and
c          its gradient components (which are at the and of array g)
c          are, at this moment, being used to approximate the hessian
c          times vector products by incremental quotients.
c
c     delta double precision
c          trust region radius (||s||_2 <= delta)
c
c     l    double precision l(n)
c          lower bounds on x + s. It components are ordered in the
c          same way as x and g.
c
c     u    double precision u(n)
c          upper bounds on x + s. It components are ordered in the
c          same way as x, g and l.
c
c     eps  double precision
c          tolerance for the stopping criterion
c          ||H s + g||_2 < eps * ||g||_2
c
c     epsnqmp double precision
c          see below
c
c     maxitnqmp integer
c          This and the previous one parameter are used for a stopping
c          criterion of the conjugate gradient subalgorithm. If the
c          progress in the quadratic model is less or equal than a
c          fraction of the best progress ( epsnqmp * bestprog ) during
c          maxitnqmp consecutive iterations then CG is stopped by not
c          enough progress of the quadratic model.
c
c          RECOMMENDED: epsnqmp = 1.0d-4, maxitnqmp = 5
c
c     maxit integer
c          maximum number of iterations allowed
c
c     nearlyq logical
c          if function f is (nearly) quadratic, use the option
c          nerlyq = TRUE. Otherwise, keep the default option.
c
c          if, in an iteration of CG we find a direction d such
c          that d^T H d <= 0 then we take the following decision:
c
c          (i) if nearlyq = TRUE then take direction d and try to
c          go to the boundary chosing the best point among the two
c          point at the boundary and the current point.
c
c          (ii) if nearlyq = FALSE then we stop at the current point.
c
c          RECOMMENDED: nearlyq = FALSE
c
c     gtype integer
c          type of gradient calculation
c          gtype = 0 means user suplied evalg subroutine,
c          gtype = 1 means central diference approximation.
c
c          RECOMMENDED: gtype = 0
c
c          (provided you have the evalg subroutine)
c
c     htvtype integer
c          type of gradient calculation
c          htvtype = 0 means user suplied evalhd subroutine,
c          htvtype = 1 means incremental quotients approximation.
c
c          RECOMMENDED: htvtype = 1
c
c          (you take some risk using this option but, a menos que
c          voce tenha uma boa evalhd subroutine, incremental
c          quotients is a very cheap option)
c
c     trtype integer
c          type of trust-region radius
c          trtype = 0 means 2-norm trust-region
c          trtype = 1 means infinite-norm trust-region
c
c          RECOMMENDED: trtype = 0
c
c     output logical
c          TRUE: print some information at each iteration,
c          FALSE: no print.
c
c     w,y,r,d,sprev double precision w(n),y(n),r(n),d(n),sprev(n)
c          working vectors
c
c     theta double precision
c          constant for the angle condition, i.e., at iteration k
c          we need a direction d_k such that
c          <g_k,d_k> <= -theta ||g||_2 ||d_k||_2,
c          where g_k is \nabla f(x_k)
c
c          RECOMMENDED: theta = 10^{-6}
c
c     sterel, steabs double precision
c          this constants mean a ``relative small number'' and ``an
c          absolute small number'' for the increments in finite
c          difference approximations of derivatives
c
c          RECOMMENDED: epsrel = 10^{-7}, epsabs = 10^{-10}
c
c     epsrel, epsabs, infty  double precision
c          this constants mean a ``relative small number'', ``an
c          absolute small number'', and ``infinite or a very big
c          number''. Basically, a quantity A is considered negligeble
c          with respect to another quantity B if
c          |A| < max ( epsrel * |B|, epsabs )
c
c          RECOMMENDED: epsrel = 10^{-10}, epsabs = 10^{-20} and
c          infty = 10^{+20}
c
c     On Return
c
c     s    double precision s(n)
c          final estimation of the solution
c
c     iter integer
c          number of conjugate-gradient iterations performed
c
c     flag integer
c          termination parameter:
c
c          0= convergence with ||H s + g||_2 <= eps * ||g||_2;
c
c          1= convergence to the boundary of ||s||_2 <= delta;
c
c          2= convergence to the boundary of l - x <= s <= u - x;
c
c          3= stopping with s= s_k  such that
c             <g,s_k> <= -theta ||g||_2 ||s_k||_2 and
c             <g,s_{k+1}> > -theta ||g||_2 ||s_{k+1}||_2;
c
c          4= not enough progress of the quadratic model during
c             maxitnqmp iterations, i.e., during maxitnqmp iterations
c             |q-qprev| .le. max ( epsrel * |q|, epsabs );
c
c          6= very similar consecutive iterates,
c             for two consecutive iterates x and y, for all i
c             |x(i)-y(i)| .le. max ( epsrel * |x(i)|, epsabs );
c
c          7= stopping with d such that d^T H d = 0 and g^T d = 0;
c
c          8= too many iterations;
c
c         11= error in evalhd subroutine.

      character*5 rbdtypea
      logical goth,samep
      integer i,itnqmp,rbdposatype,rbdnegatype,rbdposaind,rbdnegaind,
     *inform
      double precision rnorm2,rnorm2prev,beta,alpha,amax,amax1,amax2,
     *dtw,dnorm2,dts,aa,bb,cc,dd,gts,dtr,gnorm2,snorm2,q,snorm2prev,
     *qprev,amax1n,amax2n,amaxn,amax2x,amax2nx,qamax,qamaxn,norm2s,
     *bestprog,currprog,eps2

c     =======================================================
c     Initialization
c     =======================================================

      goth= .false.

      eps2 = eps**2
      gnorm2= norm2s(nind,g)

      iter= 0

      itnqmp= 0
      qprev= infty
      bestprog= 0.0d0

      do i = 1, nind
          s(i)= 0.0d0
          r(i)= g(i)
      end do

      q= 0.0d0

      gts= 0.0d0
      snorm2= 0.0d0
      rnorm2= gnorm2

c     =======================================================
c     Print initial information
c     =======================================================

      if (output) then
          write(*,980) maxit,eps
          if (trtype.eq.0) then
              write(*,981) delta
          else if (trtype.eq.1) then
              write(*,982) delta
          else
              write(*,983)
          end if
          write(*,984) iter,rnorm2,dsqrt(snorm2),q

          write(10,980) maxit,eps
          if (trtype.eq.0) then
              write(10,981) delta
          else if (trtype.eq.1) then
              write(10,982) delta
          else
              write(10,983)
          end if
          write(10,984) iter,rnorm2,dsqrt(snorm2),q

      end if

c     =======================================================
c     Main loop
c     =======================================================

 100  continue

c     =======================================================
c     Test stopping criteria
c     =======================================================

c     if ||r||_2 = ||H s + g||_2 <= eps * ||g||_2 then stop

      if (rnorm2.le.eps2*gnorm2.or.
     *(rnorm2.le.1.0d-17.and.iter.ne.0)) then

          flag= 0

          if (output) then
              write(*,990)  flag
              write(10,990) flag
          end if

          go to 500

      end if

c     if the maximum number of iterations was achieved then stop

      if (iter.ge.maxit) then

          flag= 8

          if (output) then
              write(*,998)  flag
              write(10,998) flag
          end if

          go to 500

      end if

c     =======================================================
c     Compute direction
c     =======================================================

      if (iter.eq.0) then

          dnorm2= rnorm2
          dtr= -rnorm2

	  if (dtr.gt.0.0d0) then
c     Force d to be a descent direction of q(s), i.e.,
c     <\nabla q(s), d> = <H s + g, d> = <r, d> \le 0.
	          do i= 1, nind
        	      d(i)= r(i)
	          end do
        	  dtr= -dtr

	  else
	          do i= 1, nind
        	      d(i)= -r(i)
	          end do
	  end if

      else

          beta= rnorm2/rnorm2prev
          dnorm2= rnorm2 - 2.0d0*beta*(dtr+alpha*dtw) + beta**2*dnorm2
          dtr= -rnorm2 + beta*(dtr+alpha*dtw)

	  if (dtr.gt.0.0d0) then

		do i= 1, nind
        		d(i)= r(i) - beta*d(i)
		end do
        	dtr= -dtr
          else
		do i= 1, nind
			d(i)= -r(i) + beta*d(i)
		end do
          end if
      end if

c     Force d to be a descent direction of q(s), i.e.,
c     <\nabla q(s), d> = <H s + g, d> = <r, d> \le 0.

c      if (dtr.gt.0.0d0) then

c          do i= 1, nind
c              d(i)= -d(i)
c          end do

c          dtr= -dtr

c      end if

c     =======================================================
c     Compute d^T H d
c     =======================================================

c     w= A d

      call calchd(nind,ind,x,d,g,n,x,gtype,htvtype,w,y,sterel,steabs,
     *goth,evalf,evalg,evalhd,inform)

      if (inform.ne.0) then
          flag = 11

          if (output) then
              write(*,1011) flag
              write(10,1011) flag
          end if

          go to 500
      end if

c     Compute d^T w and ||w||^2
c
c	and
c     =======================================================
c     Compute maximum step
c     =======================================================

c     amax1 > 0 and amax1n < 0 are the values of alpha such
c     that ||s + alpha * d||_2 or ||s + alpha * d||_\infty = delta

      dtw= 0.0d0
      dts= 0.0d0
      do i= 1, nind
          dtw= dtw + d(i)*w(i)
          dts= dts + d(i)*s(i)
      end do



c      dts= 0.0d0
c      do i= 1, nind
c          dts= dts + d(i)*s(i)
c      end do

c     2-norm trust-region radius

      if (trtype.eq.0) then

          aa= dnorm2
          bb= 2.0d0*dts
          cc= snorm2-delta**2
          dd= dsqrt(bb**2-4.0d0*aa*cc)

          amax1= (-bb+dd)/(2.0d0*aa)
          amax1n= (-bb-dd)/(2.0d0*aa)

c     infinite-norm trust-region radius

      else if (trtype.eq.1) then

          amax1= infty
          amax1n= -infty

          do i= 1, nind
              if (d(i).gt.0.0d0) then
                  amax1= dmin1(amax1, (delta-s(i))/d(i))
                  amax1n= dmax1(amax1n, (-delta-s(i))/d(i))
              else if (d(i).lt.0.0d0) then
                  amax1= dmin1(amax1, (-delta-s(i))/d(i))
                  amax1n= dmax1(amax1n, (delta-s(i))/d(i))
              end if
          end do

      end if

c     amax2 > 0 and amax2n < 0 are the maximum and the minimum
c     values of alpha such that l - x <= s + alpha * d <= u - x,
c     respectively

      amax2= infty
      amax2n= -infty

      do i= 1, nind
          if (d(i).gt.0.0d0) then
              if (u(i).lt.infty) then
                  amax2x= (u(i)-x(i)-s(i))/d(i)
                  if (amax2x.lt.amax2) then
                      amax2= amax2x
                      rbdposaind= i
                      rbdposatype= 2
                  end if
              end if
              if (l(i).gt.-infty) then
                  amax2nx= (l(i)-x(i)-s(i))/d(i)
                  if (amax2nx.gt.amax2n) then
                      amax2n= amax2nx
                      rbdnegaind= i
                      rbdnegatype= 1
                  end if
              end if
          else if (d(i).lt.0.0d0) then
              if (l(i).gt.-infty) then
                  amax2x= (l(i)-x(i)-s(i))/d(i)
                  if (amax2x.lt.amax2) then
                      amax2= amax2x
                      rbdposaind= i
                      rbdposatype= 1
                  end if
              end if
              if (u(i).lt.infty) then
                  amax2nx= (u(i)-x(i)-s(i))/d(i)
                  if (amax2nx.gt.amax2n) then
                      amax2n= amax2nx
                      rbdnegaind= i
                      rbdnegatype= 2
                  end if
              end if
          end if
      end do

c     Compute amax as the minimum among amax1 and amax2, and
c     amaxn as the minimum among amax1n and amax2n. Moreover
c     change amaxn by -amaxn to have amax and amaxn as maximum
c     steps along d direction (and not -d in the case of amaxn)

      amax=   dmin1(amax1,  amax2)
      amaxn=  dmax1(amax1n, amax2n)

c     =======================================================
c     Compute the step (and the quadratic functional value at
c     the new point)
c     =======================================================

      qprev= q

c     If d^T H d > 0 then take the conjugate gradients step

      if (dtw.gt.0.0d0) then

          alpha= dmin1(amax, rnorm2/dtw)

          q= q + 0.5d0*alpha**2*dtw + alpha*dtr

c     If d^T H d <= 0 and function f is nearly quadratic then
c     take the point with the minimum functional value (q) among
c     the actual one and the ones which are at the boundary, i.e.,
c     the best one between q(s), q(s + amax*d) and q(s + amaxn*d).

      else

          qamax= q + 0.5d0*amax**2*dtw + amax*dtr

c         If we are at iteration zero then take the maximum positive
c         step in the minus gradient direction

          if (iter.eq.0) then

              alpha= amax
              q= qamax

c         If we are not in the first iteration then if function f is
c         nearly quadratic and q(s + amax * d) or q(s + amaxn * d) is
c         smaller than q(s), go to the best point in the boundary

          else if (nearlyq.and.(qamax.lt.q.or.qamaxn.lt.q)) then

              qamaxn= q + 0.5d0*amaxn**2*dtw + amaxn*dtr

              if (qamax.lt.qamaxn) then
                  alpha= amax
                  q= qamax
              else
                  alpha= amaxn
                  q= qamaxn
              end if

c         Else, stop at the current point

          else

              flag= 7

              if (output) then
                  write(*,997)  flag
                  write(10,997) flag
              end if

              go to 500

          end if

      end if

c     =======================================================
c     Compute new s
c     =======================================================
c     =======================================================
c     Compute the residual r = H s + g
c     =======================================================
      snorm2prev= snorm2
      snorm2= snorm2 + alpha**2*dnorm2 + 2.0d0*alpha*dts
      rnorm2prev= rnorm2

      do i= 1, nind
          sprev(i)= s(i)
          s(i)= s(i) + alpha*d(i)
          r(i)= r(i) + alpha*w(i)
      end do
      rnorm2= norm2s(nind,r)


c     =======================================================
c     Increment number of iterations
c     =======================================================

      iter= iter + 1

c     =======================================================
c     Print information of this iteration
c     =======================================================

      if (output) then
          write(*,984)  iter,dsqrt(rnorm2),dsqrt(snorm2),q
          write(10,984) iter,dsqrt(rnorm2),dsqrt(snorm2),q
      end if

c     =======================================================
c     Test other stopping criteria
c     =======================================================

c     Test angle condition

      gts= 0.0d0
      do i= 1, nind
          gts= gts + g(i)*s(i)
      end do

      if (gts.gt.0.0d0 .or. gts**2.lt.theta**2*gnorm2*snorm2) then

          do i= 1, nind
              s(i)= sprev(i)
          end do

          snorm2= snorm2prev

          q= qprev

          flag= 3

          if (output) then
              write(*,993)  flag
              write(10,993) flag
          end if

          go to 500

      end if

c     If we are in the boundary of the box also stop

      if (alpha.eq.amax2.or.alpha.eq.amax2n) then

          if (alpha.eq.amax2) then
              rbdind= rbdposaind
              rbdtype= rbdposatype
          else ! if (alpha.eq.amax2n) then
              rbdind= rbdnegaind
              rbdtype= rbdnegatype
          end if

          if (rbdtype.eq.1) then
              rbdtypea= 'lower'
          else ! if (rbdtype.eq.2) then
              rbdtypea= 'upper'
          end if

          flag= 2

          if (output) then
              write(*,992)  flag,ind(rbdind),rbdtypea
              write(10,992) flag,ind(rbdind),rbdtypea
          end if

          go to 500

      end if

c     If we are in the boundary of the trust region then stop

      if (alpha.eq.amax1.or.alpha.eq.amax1n) then

          flag= 1

          if (output) then
              write(*,991)  flag
              write(10,991) flag
          end if

          go to 500

      end if

c     If two consecutive iterates are much close then stop

      samep= .true.
      do i= 1, nind
         if (dabs(alpha*d(i)).gt.dmax1(epsrel*dabs(s(i)),epsabs)) then
              samep= .false.
          end if
      end do

      if (samep) then

          flag= 6

          if (output) then
              write(*,996)  flag
              write(10,996) flag
          end if

          go to 500

      end if

c     Test whether we performed many iterations without good progress
c     of the quadratic model

c     if (dabs(q-qprev).le.dmax1(epsrel*dabs(qprev),epsabs)) then

c         itnqmp= itnqmp + 1

c         if (itnqmp.ge.maxitnqmp) then

c             flag= 4

c             if (output) then
c                 write(*,994)  flag,itnqmp
c                 write(10,994) flag,itnqmp
c             end if

c             go to 500

c         endif

c     else
c         itnqmp= 0
c     endif

c     Test whether we performed many iterations without good progress
c     of the quadratic model

      currprog= qprev - q
      bestprog= dmax1(currprog, bestprog)

      if (currprog.le.epsnqmp*bestprog) then

          itnqmp= itnqmp + 1

          if (itnqmp.ge.maxitnqmp) then
              flag= 4

              if (output) then
                  write(*,994)  flag,itnqmp,epsnqmp,bestprog
                  write(10,994) flag,itnqmp,epsnqmp,bestprog
              end if

              go to 500
          endif

      else
          itnqmp= 0
      endif

c     =======================================================
c     Iterate
c     =======================================================

      go to 100

c     =======================================================
c     End of main loop
c     =======================================================

c     =======================================================
c     Return
c     =======================================================

 500  continue

c     Print final information

      if (output) then
          write(*,985) min0(nind,ncomp),(s(i),i=1,min0(nind,ncomp))
          write(10,985) min0(nind,ncomp),(s(i),i=1,min0(nind,ncomp))
      end if

      return

c     Non-executable statements

 980  format(/,6x,'Conjugate gradients (maxit= ',I7,' acc= ',1PD11.4,
     *')')
 981  format(6x,'Using Euclidian trust region (delta= ',1PD11.4,
     *')')
 982  format(6x,'Using sup-norm trust region (delta= ',1PD11.4,')')
 983  format(6x,'Unknown trust-region type')
 984  format(6x,'CG iter= ',I5,' rnorm: ',1PD11.4,' snorm= ',1PD11.4,
     *' q= ',1PD11.4)
 985  format(/,6x,'Truncated Newton direction (first ',I6,
     *' components): ',/,1(6x,6(1PD11.4,1x)))
 990  format(6x,'Flag of CG= ',I2,' (Convergence with small residual)')
 991  format(6x,'Flag of CG= ',I2,
     *' (Convergence to the trust region boundary)')
 992  format(6x,'Flag of CG= ',I2,
     *' (Convergence to the boundary of the box constraints,',/,6x,
     *'taking step >= 1, variable ',I6,' will reaches its ',A5,
     *' bound)')
 993  format(6x,'Flag of CG= ',I2,
     *' (The next CG iterate will not satisfy the angle condition)')
 994  format(6x,'Flag of CG= ',I2,
     *' (Not enough progress in the quadratic model. This means',/,6x,
     *'that the progress of the last ',I7,' iterations was smaller ',
     *'than ',/,6x,1PD11.4,' times the best progress (',1PD11.4,')')
 996  format(6x,'Flag of CG= ',I2,
     *' (Very near consecutive iterates)')
 997  format(6x,'Flag of CG= ',I2,
     *' (d such that d^T H d = 0 and g^T d = 0 was found)')
 998  format(6x,'Flag of CG= ',I2,' (Too many GC iterations)')
 1011 format(6x,'Flag of CG= ',I2,' (Error in evalhd subroutine)')

      end


c     ******************************************************
c     ******************************************************
      subroutine tnls(nind,ind,n,x,f,g,d,l,u,amax,rbdtype,rbdind,fmin,
     *maxfc,gtype,output,fcnt,gcnt,intcnt,exgcnt,exbcnt,flag,xplus,
     *xtemp,gamma,beta,sigma1,sigma2,nint,next,mininterp,sterel,steabs,
     *epsrel,epsabs,infty,evalf,evalg)

      logical output
      integer nind,ind(nind),n,rbdtype,rbdind,maxfc,gtype,fcnt,gcnt,
     *intcnt,exgcnt,exbcnt,flag,mininterp
      double precision x(n),f,g(n),d(n),l(n),u(n),amax,fmin,xplus(n),
     *xtemp(n),gamma,beta,sigma1,sigma2,nint,next,sterel,steabs,epsrel,
     *epsabs,infty
     
      external evalf,evalg

c     This subrotuine implements the line search described in a working
c     paper by E. G. Birgin and J. M. Martinez.
c
c     On Entry
c
c     nind integer
c          number of free variables (this is thee dimension in
c          which this subroutine will work)
c
c     ind  integer ind(n)
c          array which contains, in the first nind positions, the
c          identifiers of the free variables
c
c     n    integer
c          dimension of the full space
c
c     x    double precision x(n)
c          actual point
c
c          The first nind positions of x contains the free variables
c          x_ind(1), x_ind(2), ..., x_ind(nind).
c
c     f    double precision
c          functional value at x
c
c     g    double precision g(n)
c          gradient vector at x
c
c          It also contains in the first nind positions the components
c          g_ind(1), g_ind(2), ..., g_ind(nind).
c
c          IMPORTANT: the linear algebra of this subroutine lies in
c          a space of dimension nind. The value of the full dimension n,
c          the non-free variables (which are at the end of array x) and
c          its gradient components (which are at the and of array g)
c          are also used and actualized any time the gradient is being
c          evaluated.
c
c     d    double precision d(nind)
c          descent direction
c
c     l    double precision l(nind)
c          lower bounds on x. It components are ordered in the
c          same way as x and g.
c
c     u    double precision u(nind)
c          upper bounds on x. It components are ordered in the
c          same way as x, g and l.
c
c     fmin double precision
c          functional value for the stopping criteria f <= fmin
c
c     maxfc integer
c          maximum number of funtion evaluations
c
c     gtype integer
c          type of gradient calculation
c          gtype = 0 means user suplied evalg subroutine,
c          gtype = 1 means central diference approximation.
c
c          RECOMMENDED: gtype = 0
c
c          (provided you have the evalg subroutine)
c
c     output logical
c          TRUE: print some information at each iteration,
c          FALSE: no print.
c
c     xplus, xtemp double precision xplus(nind),xtemp(nind)
c          working vectors
c
c     gamma double precision
c          constant for the Armijo crtierion
c          f(x + alpha d) <= f(x) + gamma * alpha * <\nabla f(x),d>
c
c          RECOMMENDED: gamma = 10^{-4}
c
c     beta double precision
c          constant for the beta condition
c          <d_k, g(x_k + d_k)>  <  beta * <d_k,g_k>
c          if (x_k + d_k) satisfies the Armijo condition but does not
c          satisfy the beta condition then the point is accepted, but
c          if it satisfied the Armijo condition and also satisfies the
c          beta condition then we know that there is the possibility
c          for a succesful extrapolation
c
c          RECOMMENDED: beta = 0.5
c
c     sigma1, sigma2 double precision
c          constant for the safeguarded interpolation
c          if alpha_new \notin [sigma1, sigma*alpha] then we take
c          alpha_new = alpha / nint
c
c          RECOMMENDED: sigma1 = 0.1 and sigma2 = 0.9
c
c     nint double precision
c          constant for the interpolation. See the description of
c          sigma1 and sigma2 above. Sometimes we take as a new trial
c          step the previous one divided by nint
c
c          RECOMMENDED: nint = 2.0
c
c     next double precision
c          constant for the extrapolation
c          when extrapolating we try alpha_new = alpha * next
c
c          RECOMMENDED: next = 2.0
c
c     mininterp integer
c          constant for testing if, after having made at least mininterp
c          interpolations, the steplength is soo small. In that case
c          failure of the line search is declared (may be the direction
c          is not a descent direction due to an error in the gradient
c          calculations)
c
c          RECOMMENDED: mininterp = 4
c
c     sterel, steabs double precision
c          this constants mean a ``relative small number'' and ``an
c          absolute small number'' for the increments in finite
c          difference approximations of derivatives
c
c          RECOMMENDED: epsrel = 10^{-7}, epsabs = 10^{-10}
c
c     epsrel, epsabs, infty  double precision
c          this constants mean a ``relative small number'', ``an
c          absolute small number'', and ``infinite or a very big
c          number''. Basically, a quantity A is considered negligeble
c          with respect to another quantity B if
c          |A| < max ( epsrel * |B|, epsabs )
c
c          RECOMMENDED: epsrel = 10^{-10}, epsabs = 10^{-20} and
c          infty = 10^{+20}
c
c     On Return
c
c     x    double precision x(n)
c          new actual point
c
c     f    double precision
c          functional value at x
c
c     g    double precision g(n)
c          gradient vector at x
c
c     fcnt integer
c          number of funtional evaluations used in this line search
c
c     gcnt integer
c          number of gradient evaluations used in this line search
c
c     intcnt integer
c          number of interpolations
c
c     exgcnt integer
c          number of good extrapolations
c
c     exbcnt integer
c          number of bad extrapolations
c
c     flag integer
c          This output parameter tells what happened in this
c          subroutine, according to the following conventions:
c
c          0= convergence with an Armijo-like criterion
c             (f(xnew) <= f(x) + 1.0d-4 * alpha * <g,d>);
c
c          4= the algorithm stopped because the functional value
c             is very small (f <= fmin);
c
c          6= soo small step in the line search. After having made at
c             least mininterp interpolations, the steplength becames
c             small. ``small steplength'' means that we are at point
c             x with direction d and step alpha, and, for all i,
c
c             |alpha * d(i)| .le. max ( epsrel * |x(i)|, epsabs ).
c
c             In that case failure of the line search is declared
c             (may be the direction is not a descent direction
c             due to an error in the gradient calculations). Use
c             mininterp > maxfc for inhibit this criterion;
c
c          8= it was achieved the maximum allowed number of
c             function evaluations (maxfc);
c
c          9= error in evalf subroutine;
c
c         10= error in evalg subroutine.

c     Armijo parameter and beta parameter. You can modify them if
c     necessary

      logical samep
      integer i,interp,inform
      double precision fplus,atemp,ftemp,gtd,gptd,alpha,fbext

c     =======================================================
c     Compute directional derivative
c     =======================================================

      gtd= 0.0d0
      do i= 1, nind
          gtd= gtd + g(i)*d(i)
      end do

c     =======================================================
c     Compute first trial
c     =======================================================

      alpha= dmin1(1.0d0, amax)

      do i= 1, nind
          xplus(i)= x(i) + alpha*d(i)
      end do

      if (alpha.eq.amax) then
          if (rbdtype.eq.1) then
              xplus(rbdind)= l(rbdind)
          else ! if (rbdtype.eq.2) then
              xplus(rbdind)= u(rbdind)
          end if
      end if

      call calcf(nind,ind,xplus,n,x,fplus,evalf,inform)
      fcnt= fcnt + 1

      if (inform.ne.0) then

          flag = 9

          if (output) then
              write(*,1000) flag
              write(10,1000) flag
          end if

          go to 500

      end if

c     Print initial information

      if (output) then
          write(*,980) amax
          write(*,999) alpha,fplus,fcnt

          write(10,980) amax
          write(10,999) alpha,fplus,fcnt
      end if

c     =======================================================
c     Test Armijo and beta-condition and decide for accepting
c     the trial point, interpolate or extrapolate.
c     =======================================================

      if (amax.gt.1.0d0) then

c         x + d belongs to the interior of the feasible set (amax > 1)

          if (output) then
              write(*,*)  '     x+d belongs to int of the feasible set'
              write(10,*) '     x+d belongs to int of the feasible set'
          end if

c         Verify Armijo

          if (fplus.le.f+gamma*alpha*gtd) then

c             Armijo condition holds
              if (output) then
                  write(*,*)  '     Armijo condition holds'
                  write(10,*) '     Armijo condition holds'
              end if

              call calcg(nind,ind,xplus,n,x,gtype,g,sterel,steabs,
     *        evalf,evalg,inform)

              
	      gcnt= gcnt + 1

              if (inform.ne.0) then

                  flag = 10

                  if (output) then
                      write(*,1001) flag
                      write(10,1001) flag
                  end if

                  go to 500

              end if

              gptd= 0.0d0
              do i= 1, nind
                  gptd= gptd + g(i)*d(i)
              end do

c             Verify directional derivative (beta condition)

              if (gptd.ge.beta*gtd) then

c                 Step = 1 was ok, finish the line search
                  if (output) then
                      write(*,*)  '     The beta condition is also true'
                      write(*,*)  '     Line search is over'
                      write(10,*) '     The beta condition is also true'
                      write(10,*) '     Line search is over'
                  end if

                  f= fplus

                  do i= 1, nind
                      x(i)= xplus(i)
                  end do

                  flag= 0

                  if (output) then
                      write(*,990)  flag
                      write(10,990) flag
                  end if

                  go to 500

              else

c                 Extrapolate
                  if (output) then
                      write(*,*) '     The beta-condition does not hold'
                      write(*,*) '     We will extrapolate'
                      write(10,*)'     The beta-condition does not hold'
                      write(10,*)'     We will extrapolate'
                  end if

c                 f before extrapolation
                  fbext= fplus

                  go to 100

              end if

          else

c             Interpolate
              if (output) then
                  write(*,*)  '     Armijo does not hold'
                  write(*,*)  '     We will interpolate'
                  write(10,*) '     Armijo does not hold'
                  write(10,*) '     We will interpolate'
              end if

              go to 200

          end if

      else

c         x + d does not belong to the feasible set (amax <= 1)
          if (output) then
              write(*,*)  '     x+d does not belong to box-interior'
              write(10,*) '     x+d does not belong to box-interior'
          end if

          if (fplus.lt.f) then

c             Extrapolate
              if (output) then
                  write(*,*)  '     f(x+d) < f(x)'
                  write(*,*)  '     We will extrapolate'
                  write(10,*) '     f(x+d) < f(x)'
                  write(10,*) '     We will extrapolate'
              end if

c             f before extrapolation
              fbext= fplus

              go to 100

          else

c             Interpolate
              if (output) then
                  write(*,*)  '     f(x+d) >= f(x)'
                  write(*,*)  '     We will interpolate'
                  write(10,*) '     f(x+d) >= f(x)'
                  write(10,*) '     We will interpolate'
              end if

              go to 200

          end if

      end if


c     =======================================================
c     Extrapolation
c     =======================================================
 100  continue

c     Test f going to -inf

 120  if (fplus.le.fmin) then

c         Finish the extrapolation with the current point

          f= fplus

          do i= 1, nind
              x(i)= xplus(i)
          end do

          call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,evalf,
     *	  evalg,inform)
          gcnt= gcnt + 1

          if (inform.ne.0) then

              flag = 10

              if (output) then
                  write(*,1001) flag
                  write(10,1001) flag
              end if

              go to 500

          end if

          if (f.lt.fbext) then
              exgcnt= exgcnt + 1
          else
              exbcnt= exbcnt + 1
          end if

          flag= 4

          if (output) then
              write(*,994) flag
              write(10,994) flag
          end if

          go to 500

      end if

c     Test maximum number of functional evaluations

      if (fcnt.ge.maxfc) then

c         Finish the extrapolation with the current point

          f= fplus

          do i= 1, nind
              x(i)= xplus(i)
          end do

          call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,evalf,
     *	  evalg,inform)
          gcnt= gcnt + 1

          if (inform.ne.0) then

              flag = 10

              if (output) then
                  write(*,1001) flag
                  write(10,1001) flag
              end if

              go to 500

          end if

          if (f.lt.fbext) then
              exgcnt= exgcnt + 1
          else
              exbcnt= exbcnt + 1
          end if

          flag= 8

          if (output) then
              write(*,998) flag
              write(10,998) flag
          end if

          go to 500

      end if

c     Chose new step

      if (alpha.lt.amax.and.next*alpha.gt.amax) then
          atemp= amax
      else
          atemp= next*alpha
      end if

c     Compute new trial point

      do i= 1, nind
          xtemp(i)= x(i) + atemp*d(i)
      end do

      if (atemp.eq.amax) then
          if (rbdtype.eq.1) then
              xtemp(rbdind)= l(rbdind)
          else ! if (rbdtype.eq.2) then
              xtemp(rbdind)= u(rbdind)
          end if
      end if

c     Project

      if (atemp.gt.amax) then
          do i= 1, nind
              xtemp(i)= dmax1(l(i),dmin1(xtemp(i), u(i)))
          end do
      end if

c     Test if this is not the same point as the previous one.
c     This test is performed only when alpha >= amax.

      if(alpha.ge.amax) then

          samep= .true.
          do i= 1, nind
              if (dabs(xtemp(i)-xplus(i)).gt.
     *        dmax1(epsrel*dabs(xplus(i)),epsabs)) then
                  samep= .false.
              end if
          end do

          if (samep) then

c             Finish the extrapolation with the current point

              f= fplus

              do i= 1, nind
                  x(i)= xplus(i)
              end do

              call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,
     *        evalf,evalg,inform)
              gcnt= gcnt + 1

              if (inform.ne.0) then

                  flag = 10

                  if (output) then
                      write(*,1001) flag
                      write(10,1001) flag
                  end if

                  go to 500

              end if

              if (f.lt.fbext) then
                  exgcnt= exgcnt + 1
              else
                  exbcnt= exbcnt + 1
              end if

              flag= 0

              if (output) then
                  write(*,990) flag
                  write(10,990) flag
              end if

              go to 500

          end if

      end if

c     Evaluate function

      call calcf(nind,ind,xtemp,n,x,ftemp,evalf,inform)
      fcnt= fcnt + 1

      if (inform.ne.0) then

          flag = 9

          if (output) then
              write(*,1000) flag
              write(10,1000) flag
          end if

          go to 500

      end if

c     Print information of this iteration

      if (output) then
          write(*,999)  atemp,ftemp,fcnt
          write(10,999) atemp,ftemp,fcnt
      end if

c     If the functional value decreases then set the current
c     point and continue the extrapolation

      if (ftemp.lt.fplus) then

          alpha= atemp

          fplus= ftemp

          do i= 1, nind
              xplus(i)= xtemp(i)
          end do

          go to 120

c     If the functional value does not decrease then discard the
c     last trial and finish the extrapolation with the previous point

      else

          f= fplus

          do i= 1, nind
              x(i)= xplus(i)
          end do

          call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,evalf,
     *	  evalg,inform)
          gcnt= gcnt + 1

          if (inform.ne.0) then

              flag = 10

              if (output) then
                  write(*,1001) flag
                  write(10,1001) flag
              end if

              go to 500

          end if

          if (f.lt.fbext) then
              exgcnt= exgcnt + 1
          else
              exbcnt= exbcnt + 1
          end if

          flag= 0

          if (output) then
              write(*,990) flag
              write(10,990) flag
          end if

          go to 500

      end if
c     =======================================================
c     End of extrapolation
c     =======================================================

c     =======================================================
c     Interpolation
c     =======================================================
 200  continue
      intcnt= intcnt + 1

c     Initialization

      interp= 0

c     Test f going to -inf

 210  if (fplus.le.fmin) then

c         Finish the interpolation with the current point

          f= fplus

          do i= 1, nind
              x(i)= xplus(i)
          end do

          call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,evalf,
     *	  evalg,inform)
          gcnt= gcnt + 1

          if (inform.ne.0) then

              flag = 10

              if (output) then
                  write(*,1001) flag
                  write(10,1001) flag
              end if

              go to 500

          end if

          flag= 4

          if (output) then
              write(*,994) flag
              write(10,994) flag
          end if

          go to 500

      end if

c     Test maximum number of functional evaluations

      if (fcnt.ge.maxfc) then

c         As this is an abrupt termination then the current point of
c         the interpolation may be worst than the intial one

c         If the current point is better than the initial one then
c         finish the interpolation with the current point else
c         discard all we did inside this line search and finish with
c         the initial point

          if (fplus.lt.f) then

              f= fplus

              do i= 1, nind
                  x(i)= xplus(i)
              end do

              call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,
     *        evalf,evalg,inform)
              gcnt= gcnt + 1

              if (inform.ne.0) then

                  flag = 10

                  if (output) then
                      write(*,1001) flag
                      write(10,1001) flag
                  end if

                  go to 500

              end if

          end if

          flag= 8

          if (output) then
              write(*,998) flag
              write(10,998) flag
          end if

          go to 500

      end if

c     Compute new step

      interp= interp + 1

      if (alpha.lt.sigma1) then
          alpha= alpha/nint

      else
          atemp= (-gtd*alpha**2)/(2.0d0*(fplus-f-alpha*gtd))

          if (atemp.lt.sigma1 .or. atemp.gt.sigma2*alpha) then
              alpha= alpha/nint

          else
              alpha= atemp
          end if
      end if

c     Compute new trial point

      do i= 1, nind
          xplus(i)= x(i) + alpha*d(i)
      end do

      call calcf(nind,ind,xplus,n,x,fplus,evalf,inform)
      fcnt= fcnt + 1

      if (inform.ne.0) then

          flag = 9

          if (output) then
              write(*,1000) flag
              write(10,1000) flag
          end if

          go to 500

      end if

c     Print information of this iteration

      if (output) then
          write(*,999)  alpha,fplus,fcnt
          write(10,999) alpha,fplus,fcnt
      end if

c     Test Armijo condition

      if (fplus.le.f+gamma*alpha*gtd) then

c         Finish the line search

          f= fplus

          do i= 1, nind
              x(i)= xplus(i)
          end do

          call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,evalf,
     *	  evalg,inform)
          gcnt= gcnt + 1

          if (inform.ne.0) then

              flag = 10

              if (output) then
                  write(*,1001) flag
                  write(10,1001) flag
              end if

              go to 500

          end if

          flag= 0

          if (output) then
              write(*,990) flag
              write(10,990) flag
          end if

          go to 500

      end if

c     Test whether at least mininterp interpolations were made and
c     two consecutive iterates are much close

      samep= .true.
      do i= 1, nind
         if (dabs(alpha*d(i)).gt.dmax1(epsrel*dabs(x(i)),epsabs)) then
             samep= .false.
         end if
      end do

      if (interp.gt.mininterp.and.samep) then

c         As this is an abrupt termination then the current point of
c         the interpolation may be worst than the intial one

c         If the current point is better than the initial one then
c         finish the interpolation with the current point else
c         discard all we did inside this line search and finish with
c         the initial point

c         if (fplus.lt.f) then

c             f= fplus

c             do i= 1, nind
c                 x(i)= xplus(i)
c             end do

c             call calcg(nind,ind,x,n,x,gtype,g,sterel,steabs,evalg,inform)
c             gcnt= gcnt + 1

c             if (inform.ne.0) then

c                 flag = 10

c                 if (output) then
c                     write(*,1001) flag
c                     write(10,1001) flag
c                 end if

c                 go to 500

c             end if

c         end if

c         The previous lines were commented because, as it is been
c         used, this subroutine must return with the intial point
c         in case of finding a very small interpolation step

          flag= 6

          if (output) then
              write(*,996)  flag
              write(10,996) flag
          end if

          go to 500

      end if

c     Else, iterate

      go to 210
c     =======================================================
c     End of interpolation
c     =======================================================

 500  continue

c     =======================================================
c     Return
c     =======================================================

      return

c     Non-executable statements

 980  format(/,6x,'TN Line search (alphamax= ',1PD11.4,')')
 999  format(6x,'Alpha= ',1PD11.4,' F= ',1PD11.4,' FE= ',I5)
 990  format(6x,'Flag of TN Line search= ',I2,
     *' (Convergence with an Armijo-like criterion)')
 994  format(6x,'Flag of TN Line search= ',I2,
     *' (Small functional value, smaller than parameter fmin)')
 996  format(6x,'Flag of TN Line search= ',I2,
     *' (Too small step in the interpolation process)')
 998  format(6x,'Flag of TN Line search= ',I2,
     *' (Too many functional evaluations)')
 1000 format(6x,'Flag of TN Line search= ',I2,
     *' (Error in evalf subroutine)')
 1001 format(6x,'Flag of TN Line search= ',I2,
     *' (Error in evalg subroutine)')

      end


c     ******************************************************
c     ******************************************************
      subroutine shrink(nind,ind,n,x,g,l,u)

      integer n, nind, ind(nind)
      double precision x(n), g(n), l(n), u(n)

c     Shrink all vectors x, g, l and u from the full dimension
c     space (dimension n) to the reduced space (dimension nind).

      integer i, indi
      double precision temp

c     Shrink x, g, l and u for the reduced space

      do i= 1, nind
           indi= ind(i)
           if (i.ne.indi) then
               temp= x(indi)
               x(indi)= x(i)
               x(i)= temp

               temp= g(indi)
               g(indi)= g(i)
               g(i)= temp

               temp= l(indi)
               l(indi)= l(i)
               l(i)= temp

               temp= u(indi)
               u(indi)= u(i)
               u(i)= temp
          end if
      end do

      return

      end


c     ******************************************************
c     ******************************************************
      subroutine expand(nind,ind,n,x,g,l,u)

      integer n, nind, ind(nind)

      double precision x(n), g(n), l(n), u(n)

c     Expands vectors x, g, l and u from the reduced space
c     (dimension nind) to the full space (dimension n).

      integer i, indi
      double precision temp

c     Expand x, g, l and u to the full space

      do i= nind, 1, -1
          indi= ind(i)
          if (i.ne.indi) then
              temp= x(indi)
              x(indi)= x(i)
              x(i)= temp

              temp= g(indi)
              g(indi)= g(i)
              g(i)= temp

              temp= l(indi)
              l(indi)= l(i)
              l(i)= temp

              temp= u(indi)
              u(indi)= u(i)
              u(i)= temp
          end if
      end do

      return

      end


c     ******************************************************
c     ******************************************************
      subroutine calcf(nind,ind,x,n,xc,f,evalf,inform)

      integer nind,ind(nind),n,inform
      double precision x(n),xc(n),f
      external evalf
c     This subroutines computes the objective function. It is
c     called from the reduced space (dimension nind), expands
c     the point x where the function will be evaluated and call
c     the subroutine evalf (provided by the user) to compute
c     the objective function. Finally, returns vector x to the
c     reduced space (shrinking).
c
c     About subroutines named calc[something]. The subroutines
c     whos names start with ``calc'' work in (are called from)
c     the reduced space. Their task is (i) expand the arguments
c     to the full space, (ii) call the corresponding ``eval''
c     subroutine (which works in the full space), and (iii)
c     shrink the parameters again and also shrink an eventualy
c     output of the ``eval'' subroutines. Subroutines of this
c     type are: calcf, calcg, calchd and calchddiff (the last
c     one called from calchd) and the corresponding subroutines
c     in the full space are evalf, evalg and evalhd.

      integer i,indi
      double precision temp

c     Complete x

      do i= nind+1, n
          x(i)= xc(i)
      end do

c     Expand x to the full space

      do i= nind, 1, -1
          indi= ind(i)
          if (i.ne.indi) then
              temp= x(indi)
              x(indi)= x(i)
              x(i)= temp
          end if
      end do

c     Compute f

      call evalf(n,x,f,inform)

c     Shrink x to the reduced space

      do i= 1, nind
          indi= ind(i)
          if (i.ne.indi) then
              temp= x(indi)
              x(indi)= x(i)
              x(i)= temp
          end if
      end do

      return

      end


c     ******************************************************
c     ******************************************************
      subroutine calcg(nind,ind,x,n,xc,gtype,g,sterel,steabs,evalf,
     *evalg,inform)

      integer nind,ind(nind),n,gtype,inform
      double precision x(n),xc(n),g(n),sterel,steabs
      external evalf,evalg

c     This subroutine computes the gradient vector g(x). The way
c     it is computed depends on parameter gtype:
c
c     gtype = 0: a user defined function, called evalg, is used,
c     gtype = 1: central finite differences are used.
c
c     It is called from the reduced space (dimension nind), expands
c     the point x where the gradient will be evaluated and call
c     the subroutine evalg (provided by the user) to compute
c     the gradient vector. Finally, shrinks vectors x and g to the
c     reduced space.
c
c     About subroutines named calc[something]. The subroutines
c     whos names start with ``calc'' work in (are called from)
c     the reduced space. Their task is (i) expand the arguments
c     to the full space, (ii) call the corresponding ``eval''
c     subroutine (which works in the full space), and (iii)
c     shrink the parameters again and also shrink an eventualy
c     output of the ``eval'' subroutines. Subroutines of this
c     type are: calcf, calcg, calchd and calchddiff (the last
c     one called from calchd) and the corresponding subroutines
c     in the full space are evalf, evalg and evalhd.

      integer i,indi
      double precision temp

c     Complete x

      do i= nind+1, n
          x(i)= xc(i)
      end do

c     Expand x to the full space

      do i= nind, 1, -1
          indi= ind(i)
          if (i.ne.indi) then
              temp= x(indi)
              x(indi)= x(i)
              x(i)= temp
          end if
      end do

c     Compute gradient vector

c     True gradient

      if (gtype.eq.0) then
          call evalg(n,x,g,inform)

c     Central finite diferences approximation

      else if (gtype.eq.1) then
          call evalgdiff(n,x,g,sterel,steabs,evalf,inform)

      end if

c     shrink x and g to the reduced space

      do i= 1, nind
          indi= ind(i)
          if (i.ne.indi) then
              temp= x(indi)
              x(indi)= x(i)
              x(i)= temp

              temp= g(indi)
              g(indi)= g(i)
              g(i)= temp
          end if
      end do

      return

      end


c ****************************************************
c ****************************************************
      subroutine evalgdiff(n,x,g,sterel,steabs,evalf,inform)

      integer n,inform
      double precision x(n),g(n),sterel,steabs
      external evalf

c     Computes the gradient vector by central finite differences.
c     This subroutine, which works in the full space, is prepared
c     to replace the subroutine evalg (to evaluate the gradient
c     vector) in the case of the lastest have not being provided
c     by the user.

      integer j
      double precision tmp,step,fplus,fminus

      do j= 1, n
          tmp= x(j)
          step= dmax1(steabs, sterel*dabs(tmp))

          x(j)= tmp + step
          call evalf(n,x,fplus,inform)

          x(j)= tmp - step
          call evalf(n,x,fminus,inform)

          g(j)= (fplus-fminus) / (2.0d0*step)
          x(j)= tmp
      end do

      return

      end


c     ******************************************************
c     ******************************************************
      subroutine calchd(nind,ind,x,d,g,n,xc,gtype,htvtype,hd,xtemp,
     *sterel,steabs,goth,evalf,evalg,evalhd,inform)

      logical goth
      integer nind,ind(nind),n,gtype,htvtype,inform
      double precision x(n),d(n),g(n),xc(n),hd(n),xtemp(n),sterel,steabs
      external evalf,evalg,evalhd

c     This subroutine computes the product Hessian times vector d.
c     The way it is computed depends on parameter htvtype:
c
c     mvptype = 0: a user subroutine, called evalhd, for computing
c     the hessian times vector d product is called,
c
c     mvptype = 1: a incremental quotients aproximation is used.
c
c     If a user subroutine will be used then this subroutine (which
c     is called from the reduced space) expands vectors x and d,
c     calls the user supplied subroutine to compute the hessian times
c     vector d product, and shrinks vectors x, d and hd.
c
c     About subroutines named calc[something]. The subroutines
c     whos names start with ``calc'' work in (are called from)
c     the reduced space. Their task is (i) expand the arguments
c     to the full space, (ii) call the corresponding ``eval''
c     subroutine (which works in the full space), and (iii)
c     shrink the parameters again and also shrink an eventualy
c     output of the ``eval'' subroutines. Subroutines of this
c     type are: calcf, calcg, calchd and calchddiff (the last
c     one called from calchd) and the corresponding subroutines
c     in the full space are evalf, evalg and evalhd.

      integer i,indi
      double precision temp

c     =======================================================
c     User defined subroutine to compute the Hessian times
c     vector d product (it works in the full dimension space)
c     =======================================================

      if (htvtype.eq.0) then

c         Complete d with zeroes

          do i= nind+1, n
              d(i)= 0.0d0
          end do

c         Complete x

          do i= nind+1, n
              x(i)= xc(i)
          end do

c         Expand x, d and g to the full space

          do i= nind, 1, -1
              indi= ind(i)
              if (i.ne.indi) then
                  temp= x(indi)
                  x(indi)= x(i)
                  x(i)= temp

                  temp= d(indi)
                  d(indi)= d(i)
                  d(i)= temp

                  temp= g(indi)
                  g(indi)= g(i)
                  g(i)= temp
              end if
          end do

c         Call the user defined subroutine

          call evalhd(nind,ind,n,x,d,hd,inform)

c         Shrink x, d, g and hd to the reduced space

          do i= 1, nind
              indi= ind(i)
              if (i.ne.indi) then
                  temp= x(indi)
                  x(indi)= x(i)
                  x(i)= temp

                  temp= d(indi)
                  d(indi)= d(i)
                  d(i)= temp

                  temp= g(indi)
                  g(indi)= g(i)
                  g(i)= temp

                  temp= hd(indi)
                  hd(indi)= hd(i)
                  hd(i)= temp
              end if
          end do


c     =======================================================
c     Incremental quotients approximation
c     (it works in the reduced space)
c     =======================================================

      else if (htvtype.eq.1) then
          call calchddiff(nind,ind,x,d,g,n,xc,gtype,hd,xtemp,sterel,
     *    steabs,evalf,evalg,inform)

      end if

      return

      end


c ****************************************************
c ****************************************************
      subroutine calchddiff(nind,ind,x,d,g,n,xc,gtype,hd,xtemp,sterel,
     *steabs,evalf,evalg,inform)

      integer nind,ind(n),n,gtype,inform
      double precision x(n),d(n),g(n),xc(n),hd(n),xtemp(n),sterel,steabs
      external evalf,evalg

c     This subroutine computes the Hessian times vector d product
c     by means of a ``directional finite difference''. The idea is
c     that, at the current point x, the product H d is the limit of
c
c     [ Gradient(x + t d) - Gradient(x) ] / t
c
c     In this implementation we use
c
c     t = max(steabs, sterel ||x||_\infty) / ||d||_\infty
c
c     provided that d not equal 0, of course.
c
c     So, we evaluate the Gradient at the auxiliary point x + t d
c     and use the quotient above to approximate H d.
c
c     About subroutines named calc[something]. The subroutines
c     whos names start with ``calc'' work in (are called from)
c     the reduced space. Their task is (i) expand the arguments
c     to the full space, (ii) call the corresponding ``eval''
c     subroutine (which works in the full space), and (iii)
c     shrink the parameters again and also shrink an eventualy
c     output of the ``eval'' subroutines. Subroutines of this
c     type are: calcf, calcg, calchd and calchddiff (the last
c     one called from calchd) and the corresponding subroutines
c     in the full space are evalf, evalg and evalhd.
c
c     On Entry
c
c     n     integer
c           order of the x
c
c     x     double precision x(n)
c           point for which Hessian(x) times d will be approximated
c
c     d     double precision d(n)
c           vector for which the Hessian times vetor product will
c           be approximated
c
c     g     double precision g(n)
c           gradient at x
c
c     xtemp double precision xtemp(n)
c           working vector
c
c     sterel, steabs double precision
c           this constants mean a ``relative small number'' and
c           ``an absolute small number''
c
c     On Return
c
c     hd    double precision hd(n)
c           approximation of H d

      integer i
      double precision xinfn,dinfn,step

c     Compute incremental quotients step

      xinfn= 0.0d0
      dinfn= 0.0d0
      do i= 1, nind
          xinfn= dmax1(xinfn, dabs(x(i)))
          dinfn= dmax1(dinfn, dabs(d(i)))
      end do

      step= dmax1(sterel*xinfn,steabs) / dinfn

c     Set the point in which the gradient will be
c     evaluated: xtemp = x + step * d

      do i= 1, nind
          xtemp(i)= x(i) + step*d(i)
      end do

c     Evaluate the gradient at (x + step * d)

      call calcg(nind,ind,xtemp,n,xc,gtype,hd,sterel,steabs,evalf,
     *evalg,inform)

c     Compute incremental quotients

      do i= 1, nind
          hd(i)= (hd(i)-g(i)) / step
      end do

      return

      end


c ****************************************************
c ****************************************************
      double precision function norm2s(n,x)

c     Slightly modified version of the BLAS dnrm2 function

      integer n
      double precision x(n)

c     integer i

c     double precision absxi,norm2s,scale,ssq
      double precision hsldnrm2

      norm2s= hsldnrm2(n,x,1) ** 2
      return

c     if (n.lt.1) then
c         norm2s= 0.0d0
c     else if (n.eq.1) then
c         norm2s= dabs(x(1))
c     else
c         scale= 0.0d0
c         ssq= 1.0d0
c         do i= 1, n
c             if (x(i).ne.0.0d0) then
c                 absxi= dabs(x(i))
c                 if (scale.lt.absxi) then
c                     ssq= 1.0d0 + ssq*(scale/absxi)**2
c                     scale= absxi
c                 else
c                     ssq= ssq + (absxi/scale)**2
c                 end if
c             end if
c         end do
c         norm2s= (ssq * scale) * scale
c     end if

c     return

      end

      DOUBLE PRECISION FUNCTION HSLDNRM2(N,DX,INCX)
      DOUBLE PRECISION ZERO,ONE
      PARAMETER (ZERO=0.0D0,ONE=1.0D0)
      DOUBLE PRECISION CUTLO,CUTHI
      PARAMETER (CUTLO=8.232D-11,CUTHI=1.304D19)
      INTEGER INCX,N
      DOUBLE PRECISION DX(*)
      DOUBLE PRECISION HITEST,SUM,XMAX
      INTEGER I,J,NEXT,NN
      INTRINSIC DABS,DSQRT,FLOAT
      IF (N.GT.0) GO TO 10
      HSLDNRM2 = ZERO
      GO TO 300
   10 ASSIGN 30 TO NEXT
      SUM = ZERO
      NN = N*INCX
      I = 1
   20 GO TO NEXT
   30 IF (DABS(DX(I)).GT.CUTLO) GO TO 85
      ASSIGN 50 TO NEXT
      XMAX = ZERO
   50 IF (DX(I).EQ.ZERO) GO TO 200
      IF (DABS(DX(I)).GT.CUTLO) GO TO 85
      ASSIGN 70 TO NEXT
      GO TO 105
  100 I = J
      ASSIGN 110 TO NEXT
      SUM = (SUM/DX(I))/DX(I)
  105 XMAX = DABS(DX(I))
      GO TO 115
   70 IF (DABS(DX(I)).GT.CUTLO) GO TO 75
  110 IF (DABS(DX(I)).LE.XMAX) GO TO 115
      SUM = ONE + SUM* (XMAX/DX(I))**2
      XMAX = DABS(DX(I))
      GO TO 200
  115 SUM = SUM + (DX(I)/XMAX)**2
      GO TO 200
   75 SUM = (SUM*XMAX)*XMAX
   85 HITEST = CUTHI/DFLOAT(N)
      DO 95 J = I,NN,INCX
        IF (DABS(DX(J)).GE.HITEST) GO TO 100
   95 SUM = SUM + DX(J)**2
      HSLDNRM2 = DSQRT(SUM)
      GO TO 300
  200 CONTINUE
      I = I + INCX
      IF (I.LE.NN) GO TO 20
      HSLDNRM2 = XMAX*DSQRT(SUM)
  300 CONTINUE
      RETURN
      END

c     DOUBLE PRECISION FUNCTION MI2DNRM2 ( N, DX, INCX)
c     INTEGER          N, INCX, NEXT
c     DOUBLE PRECISION DX( * ), CUTLO, CUTHI, HITEST, SUM,
c    *                 XMAX, ZERO, ONE
c     INTRINSIC        ABS, SQRT
c     INTEGER          I, J, NN
c     PARAMETER ( ZERO = 0.0D+0, ONE = 1.0D+0 )
C
C     EUCLIDEAN NORM OF THE N-VECTOR STORED IN DX() WITH STORAGE
C     INCREMENT INCX .
C     IF    N .LE. 0 RETURN WITH RESULT = 0.
C     IF N .GE. 1 THEN INCX MUST BE .GE. 1
C
C           C.L.LAWSON, 1978 JAN 08
C
C     FOUR PHASE METHOD     USING TWO BUILT-IN CONSTANTS THAT ARE
C     HOPEFULLY APPLICABLE TO ALL MACHINES.
C         CUTLO = MAXIMUM OF  DSQRT(U/EPS)  OVER ALL KNOWN MACHINES.
C         CUTHI = MINIMUM OF  DSQRT(V)      OVER ALL KNOWN MACHINES.
C     WHERE
C         EPS = SMALLEST NO. SUCH THAT EPS + 1. .GT. 1.
C         U   = SMALLEST POSITIVE NO.   (UNDERFLOW LIMIT)
C         V   = LARGEST  NO.            (OVERFLOW  LIMIT)
C
C     BRIEF OUTLINE OF ALGORITHM..
C
C     PHASE 1    SCANS ZERO COMPONENTS.
C     MOVE TO PHASE 2 WHEN A COMPONENT IS NONZERO AND .LE. CUTLO
C     MOVE TO PHASE 3 WHEN A COMPONENT IS .GT. CUTLO
C     MOVE TO PHASE 4 WHEN A COMPONENT IS .GE. CUTHI/M
C     WHERE M = N FOR X() REAL AND M = 2*N FOR COMPLEX.
C
C     VALUES FOR CUTLO AND CUTHI..
C     FROM THE ENVIRONMENTAL PARAMETERS LISTED IN THE IMSL CONVERTER
C     DOCUMENT THE LIMITING VALUES ARE AS FOLLOWS..
C     CUTLO, S.P.   U/EPS = 2**(-102) FOR  HONEYWELL.  CLOSE SECONDS ARE
C                   UNIVAC AND DEC AT 2**(-103)
C                   THUS CUTLO = 2**(-51) = 4.44089E-16
C     CUTHI, S.P.   V = 2**127 FOR UNIVAC, HONEYWELL, AND DEC.
C                   THUS CUTHI = 2**(63.5) = 1.30438E19
C     CUTLO, D.P.   U/EPS = 2**(-67) FOR HONEYWELL AND DEC.
C                   THUS CUTLO = 2**(-33.5) = 8.23181D-11
C     CUTHI, D.P.   SAME AS S.P.  CUTHI = 1.30438D19
c     DATA CUTLO, CUTHI / 8.232D-11,  1.304D19 /
C
c     IF ( N .LE. 0) THEN
c        MI2DNRM2  = ZERO
c     ELSE
c        NEXT = 1
c        SUM  = ZERO
c        NN   = N * INCX
C
C  BEGIN MAIN LOOP
c
c        I = 1
c  20    CONTINUE
c        GO TO ( 30, 50, 70, 110 ), NEXT
c  30    CONTINUE
c        IF( ABS( DX( I ) ) .GT. CUTLO ) GO TO 85
c        NEXT = 2
c        XMAX = ZERO
C
C  PHASE 1.  SUM IS ZERO
C
c  50    CONTINUE
c        IF ( DX( I ) .EQ. ZERO ) GO TO 200
c        IF ( ABS( DX( I ) ) .GT. CUTLO ) GO TO 85
C
C  PREPARE FOR PHASE 2.
C
c        NEXT = 3
c        GO TO 105
C
C  PREPARE FOR PHASE 4.
C
c 100    CONTINUE
c        I    = J
c        NEXT = 4
c        SUM  = ( SUM / DX( I ) ) / DX( I )
c 105    CONTINUE
c        XMAX = ABS( DX( I ) )
c        SUM  = SUM + ( DX( I ) / XMAX ) ** 2
c        GO TO 200
C
C  PHASE 2.  SUM IS SMALL. SCALE TO AVOID DESTRUCTIVE UNDERFLOW.
C
c  70    CONTINUE
c        IF ( ABS( DX( I ) ) .GT. CUTLO ) THEN
C
C  PREPARE FOR PHASE 3.
C
c           SUM = ( SUM * XMAX) * XMAX
c           GO TO 85
c        END IF
C
C  COMMON CODE FOR PHASES 2 AND 4.
C  IN PHASE 4 SUM IS LARGE.  SCALE TO AVOID OVERFLOW.
C
c 110    CONTINUE
c        IF ( ABS( DX( I ) ) .GT. XMAX ) THEN
c           SUM  = ONE + SUM * ( XMAX / DX( I ) ) ** 2
c           XMAX = ABS( DX( I ) )
c        ELSE
c           SUM = SUM + ( DX( I ) / XMAX ) ** 2
c        END IF
c 200    CONTINUE
c        I = I + INCX
c        IF ( I .LE. NN ) GO TO 20
C
C  END OF MAIN LOOP.
C
C  COMPUTE SQUARE ROOT AND ADJUST FOR SCALING.
C
c        MI2DNRM2 = XMAX * SQRT(SUM)
c        GO TO 300
C
C  FOR REAL OR D.P. SET HITEST = CUTHI/N
C
c  85    CONTINUE
c        HITEST = CUTHI/FLOAT( N )
C
C  PHASE 3. SUM IS MID-RANGE.  NO SCALING.
C
c        DO 95 J = I, NN, INCX
c           IF( ABS( DX( J ) ) .GE. HITEST ) GO TO 100
c           SUM = SUM + DX( J ) ** 2
c  95    CONTINUE
c        MI2DNRM2 = SQRT( SUM )
c     END IF
c 300 CONTINUE
c     RETURN
c     END

c     Modifications introduced from March 1st to March 21th of 2002
c     in ocassion of the ISPG development:
c
c     1) Comments of some new parameters introduzed in the previous
c     modification
c
c     2) As it was, in the first iteration of GENCAN (when kappa
c     takes value equal 1) and for one-dimensional faces, cgmaxit
c     (the maximum number of Conjugate Gradient iterations to compute
c     the internal to the face truncated-Newton direction) was being 0.
c     As it is obviously wrong, we add a max between what was being
c     computed and one to allow at least one CG iteration.
c
c     3) Parameter inform in subroutines evalf, evalg and evalhd
c     supplied by the user was added
c
c     Modifications introduced from May 31th to November 2nd of 2001
c     in ocassion of the ALGENCAN development:
c
c     Fixed bugs:
c
c     1) The first spectral steplength was not been projected in the
c     [lammin,lammax] interval.
c
c     2) The conjugate gradients accuracy (cgeps) which is linearly
c     dependent of the euclidian norm of the projected gradient, was
c     also not been projected in the interval [cgepsi,cgepsf].
c
c     3) Conjugate gradients said that it was being used an euclidian
c     norm trust region when it has really being used an infinite norm
c     trust region and viceversa.
c
c     4) Sometimes, the analytic gradient has been used although the
c     user choose the finite differences option.
c
c     Modifications:
c
c     1) To avoid roundoff errors, an explicit detection of at least one
c     variable reaching its bound when a maximum step is being made was
c     added.
c
c     2) The way in which two points were considered very similar in, for
c     example, the interpolations and the extrapolations (which was
c     dependent of the infinity norm of the points) showed to be very
c     scale dependent. A new version which test the difference coordinate
c     to coordinate was done. In this was the calculus of the current
c     point x and the descent direction sup-norm is not done any
c     more.
c
c     3) The same constants epsrel and epsabs were used as small
c     relative and absolute values for, for example, detecting similar
c     points and for finite diferences. Now,
c     epsrel and epsabs are used for detecting similar points
c     (and the recommended values are 10^{-10} and 10^{-20}, respectively)
c     and new constants sterel ans steabs were introduced for finite
c     differences (and the recommended values are 10^{-7} and 10^{-10},
c     respectively).
c
c     4) Two new stopping criteria for CG were added: (i) we stop if
c     two consecutive iterates are too  close; and (ii) we also
c     stop if there is no enough quadratic model progress during
c     maxitnqmp iterations.
c
c     5) The linear relation between the conjugate gradient accuracy
c     and the norm of the projected gradient can be computed using
c     the euclidian- and the sup-norm of the projected gradient (only
c     euclidian-norm version was present in the previous version. The
c     linear relation is such that the CG accuracy is cgepsi when the
c     projected gradient norm value is equal to the value corresponding
c     to the initial guess and the CG accuracy is cgepsf when the
c     projected gradient norm value is cgrelf).
c
c     6) Inside Conjugate Gradients, the euclidian-norm is been
c     computed using an algorithm developed by C.L.LAWSON, 1978 JAN 08.
c     Numerical experiments showed that the performance of GENCAN depends
c     basically on the conjugate gradients performance and stopping
c     criteria and that the conjugate gradients depends on the way the
c     euclidian-norm is been computed. These things deserve further
c     research.
c
c     7) In the Augmented Lagrangean algorithm ALGENCAN, which uses
c     GENCAN to solve the bounded constrained subproblems, the maximum
c     number of Conjugate Gradients iterations (cgmaxit), which in
c     this version is linearly dependent of the projected gradient norm,
c     was set to 2 * (# of free variables). As CG is not using restarts
c     we do not know very well what this means. On the other hand,
c     the accuracy (given by cgeps) continues being more strict when
c     we are near to the solution and less strict when we ar far from
c     the solution.
c
c     8) Many things in the output were changed.

c -------------------------------------------------------

c -- 
c Ernesto G. Birgin
c Department of Computer Science IME-USP
c http://www.ime.usp.br/~egbirgin

