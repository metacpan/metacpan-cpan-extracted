      subroutine spg(n,x,m,eps,eps2,maxit,maxfc,output,f,pginfn,pgtwon,
     +               iter,fcnt,gcnt,flag, evalf, evalg, proj)

C     Subroutine SPG implements the Spectral Projected Gradient
C     Method (Version 2: "continuous projected gradient direction") 
C     to find the local minimizers of a given function with convex
C     constraints, described in 
C
C     E. G. Birgin, J. M. Martinez, and M. Raydan, "Nonmonotone 
C     spectral projected gradient methods on convex sets", SIAM 
C     Journal on Optimization 10, pp. 1196-1211, 2000.
C 
C     and
C 
C     E. G. Birgin, J. M. Martinez, and M. Raydan, "SPG: software 
C     for convex-constrained optimization", ACM Transactions on 
C     Mathematical Software, 2001 (to appear).
C
C     The user must supply the external subroutines evalf, evalg 
C     and proj to evaluate the objective function and its gradient 
C     and to project an arbitrary point onto the feasible region.
C
C     This version 17 JAN 2000 by E.G.Birgin, J.M.Martinez and M.Raydan.
C     Reformatted 03 OCT 2000 by Tim Hopkins.
C     Final revision 03 JUL 2001 by E.G.Birgin, J.M.Martinez and M.Raydan.
C
C     On Entry:
C
C     n     integer,
C           size of the problem,
C
C     x     double precision x(n),
C           initial guess,
C
C     m     integer,
C           number of previous function values to be considered 
C           in the nonmonotone line search,
C
C     eps   double precision,
C           stopping criterion: ||projected grad||_inf < eps,
C
C     eps2  double precision,
C           stopping criterion: ||projected grad||_2 < eps2,
C
C     maxit integer,
C           maximum number of iterations,
C
C     maxfc integer,
C           maximum number of function evaluations,
C
C     output logical,
C           true: print some information at each iteration,
C           false: no print.
C
C     On Return:
C
C     x     double precision x(n),
C           approximation to the local minimizer,
C
C     f     double precision,
C           function value at the approximation to the local
C           minimizer,
C
C     pginfn double precision,
C           ||projected grad||_inf at the final iteration,
C
C     pgtwon double precision,
C           ||projected grad||_2^2 at the final iteration,
C
C     iter  integer,
C           number of iterations,
C
C     fcnt  integer,
C           number of function evaluations,
C
C     gcnt  integer,
C           number of gradient evaluations,
C
C     flag  integer,
C           termination parameter:
C           0= convergence with projected gradient infinite-norm,
C           1= convergence with projected gradient 2-norm,
C           2= too many iterations,
C           3= too many function evaluations,
C           4= error in proj subroutine,
C           5= error in evalf subroutine,
C           6= error in evalg subroutine.

C     PARAMETERS
      double precision lmin
      parameter (lmin=1.0d-30)
      double precision lmax
      parameter (lmax=1.0d+30)
      integer nmax
      parameter (nmax=100000)
      integer mmax
      parameter (mmax=100)

C     SCALAR ARGUMENTS
      double precision pginfn,pgtwon,eps,eps2,f
      integer fcnt,flag,gcnt,iter,m,maxfc,maxit,n
      logical output

C     ARRAY ARGUMENTS
      double precision x(n)

C     LOCAL SCALARS
      double precision fbest,fnew,gtd,lambda,sts,sty
      integer i,lsflag,inform

C     LOCAL 
      double precision pg(nmax),g(nmax),gnew(nmax),s(nmax),y(nmax),
     +                 d(nmax),xbest(nmax),xnew(nmax),lastfv(0:mmax-1)

C     EXTERNAL SUBROUTINES
      external ls,evalf,evalg,proj

C     INTRINSIC FUNCTIONS
      intrinsic abs,max,min,mod

C     INITIALIZATION

      iter = 0
      fcnt = 0
      gcnt = 0

      do i = 0,m - 1
          lastfv(i) = -1.0d+99
      end do

C     PROJECT INITIAL GUESS

      call proj(n,x,inform)

      if (inform .ne. 0) then
        ! ERROR IN PROJ SUBROUTINE, STOP
          flag = 4
          go to 200
      end if

C     INITIALIZE BEST SOLUTION

      do i = 1,n
          xbest(i) = x(i)
      end do

C     EVALUATE FUNCTION AND GRADIENT

      call evalf(n,x,f,inform)
      fcnt = fcnt + 1

      if (inform .ne. 0) then
        ! ERROR IN EVALF SUBROUTINE, STOP
          flag = 5
          go to 200
      end if

      call evalg(n,x,g,inform)
      gcnt = gcnt + 1

      if (inform .ne. 0) then
        ! ERROR IN EVALG SUBROUTINE, STOP
          flag = 6
          go to 200
      end if

C     STORE FUNCTION VALUE FOR THE NONMONOTONE LINE SEARCH

      lastfv(0) = f

C     INITIALIZE BEST FUNCTION VALUE

      fbest = f

C     COMPUTE CONTINUOUS PROJECTED GRADIENT (AND ITS NORMS)

      do i = 1,n
          pg(i) = x(i) - g(i)
      end do

      call proj(n,pg,inform)

      if (inform .ne. 0) then
        ! ERROR IN PROJ SUBROUTINE, STOP
          flag = 4
          go to 200
      end if

      pgtwon = 0.0D0
      pginfn = 0.0D0
      do i = 1,n
          pg(i) = pg(i) - x(i)
          pgtwon = pgtwon + pg(i)**2
          pginfn = max(pginfn,abs(pg(i)))
      end do

C     PRINT ITERATION INFORMATION

      if (output) then
          write (*,fmt=9010) iter,f,pginfn
      end if

C     DEFINE INITIAL SPECTRAL STEPLENGTH

      if (pginfn .ne. 0.0d0) then
          lambda =  min(lmax,max(lmin,1.0d0/pginfn))
      end if

C     MAIN LOOP

C     TEST STOPPING CRITERIA

 100  continue

      if (pginfn .le. eps) then
        ! GRADIENT INFINITE-NORM STOPPING CRITERION SATISFIED, STOP
          flag = 0
          go to 200
      end if

      if (pgtwon .le. (eps2*eps2)) then
        ! GRADIENT 2-NORM STOPPING CRITERION SATISFIED, STOP
          flag = 1
          go to 200
      end if

      if (iter .gt. maxit) then
        ! MAXIMUM NUMBER OF ITERATIONS EXCEEDED, STOP
          flag = 2
          go to 200
      end if

      if (fcnt .gt. maxfc) then
        ! MAXIMUM NUMBER OF FUNCTION EVALUATIONS EXCEEDED, STOP
          flag = 3
          go to 200
      end if

C     DO AN ITERATION

      iter = iter + 1

C     COMPUTE THE SPECTRAL PROJECTED GRADIENT DIRECTION
C     AND <G,D>

      do i = 1,n
          d(i) = x(i) - lambda*g(i)
      end do

      call proj(n,d,inform)

      if (inform .ne. 0) then
        ! ERROR IN PROJ SUBROUTINE, STOP
          flag = 4
          go to 200
      end if

      gtd = 0.0d0
      do i = 1,n
          d(i) = d(i) - x(i)
          gtd = gtd + g(i)*d(i)
      end do

C     NONMONOTONE LINE SEARCH

      call ls(n,x,f,d,gtd,m,lastfv,maxfc,fcnt,fnew,xnew,lsflag,evalf)

      if (lsflag .eq. 3) then
        ! THE NUMBER OF FUNCTION EVALUATIONS WAS EXCEEDED 
        ! INSIDE  THE LINE SEARCH, STOP
          flag = 3
          go to 200
      end if

C     SET NEW FUNCTION VALUE AND SAVE IT FOR THE NONMONOTONE
C     LINE SEARCH

      f = fnew
      lastfv(mod(iter,m)) = f

C     COMPARE THE NEW FUNCTION VALUE AGAINST THE BEST FUNCTION 
C     VALUE  AND, IF SMALLER, UPDATE THE BEST FUNCTION 
C     VALUE AND THE CORRESPONDING BEST POINT

      if (f .lt. fbest) then
          fbest = f
          do i = 1,n
              xbest(i) = xnew(i)
          end do
      end if

C     EVALUATE THE GRADIENT AT THE NEW ITERATE

      call evalg(n,xnew,gnew,inform)
      gcnt = gcnt + 1

      if (inform .ne. 0) then
        ! ERROR IN EVALG SUBROUTINE, STOP
          flag = 6
          go to 200
      end if

C     COMPUTE S = XNEW - X, Y = GNEW - G, <S,S>, <S,Y>,
C     THE CONTINUOUS PROJECTED GRADIENT AND ITS NORMS

      sts = 0.0d0
      sty = 0.0d0
      do i = 1,n
          s(i) = xnew(i) - x(i)
          y(i) = gnew(i) - g(i)
          sts = sts + s(i)*s(i)
          sty = sty + s(i)*y(i)
          x(i) = xnew(i)
          g(i) = gnew(i)
          pg(i) = x(i) - g(i)
      end do

      call proj(n,pg,inform)

      if (inform .ne. 0) then
        ! ERROR IN PROJ SUBROUTINE, STOP
          flag = 4
          go to 200
      end if

      pgtwon = 0.0D0
      pginfn = 0.0D0
      do i = 1,n
          pg(i) = pg(i) - x(i)
          pgtwon = pgtwon + pg(i)**2
          pginfn = max(pginfn,abs(pg(i)))
      end do

C     PRINT ITERATION INFORMATION

      if (output) then
          write (*,fmt=9010) iter,f,pginfn
      end if

C     COMPUTE SPECTRAL STEPLENGTH

      if (sty .le. 0.0d0) then
          lambda = lmax

      else
          lambda = min(lmax,max(lmin,sts/sty))
      end if

C     FINISH THE ITERATION

      go to 100

C     STOP

 200  continue

C     SET X AND F WITH THE BEST SOLUTION AND ITS FUNCTION VALUE

      f = fbest
      do i = 1,n
          x(i) = xbest(i)
      end do

 9010 format ('ITER= ',I10,' F= ',1P,D17.10,' PGINFNORM= ',1P,D17.10)

      end


      subroutine ls(n,x,f,d,gtd,m,lastfv,maxfc,fcnt,fnew,xnew,flag,evaf)

C     Subroutine LS implements a nonmonotone line search with
C     safeguarded quadratic interpolation.
C
C     This version 17 JAN 2000 by E.G.Birgin, J.M.Martinez and M.Raydan.
C     Reformatted 03 OCT 2000 by Tim Hopkins.
C     Final revision 03 JUL 2001 by E.G.Birgin, J.M.Martinez and M.Raydan.
C
C     On Entry:
C
C     n     integer,
C           size of the problem,
C
C     x     double precision x(n),
C           initial guess,
C
C     f     double precision,
C           function value at the actual point,
C
C     d     double precision d(n),
C           search direction,
C
C     gtd   double precision,
C           internal product <g,d>, where g is the gradient at x,
C
C     m     integer,
C           number of previous function values to be considered 
C           in the nonmonotone line search,
C
C     lastfv double precision lastfv(m),
C           last m function values,
C
C     maxfc integer,
C           maximum number of function evaluations,
C
C     fcnt  integer,
C           actual number of function evaluations.
C
C     On Return:
C
C     fcnt  integer,
C           actual number of function evaluations,
C
C     fnew  double precision,
C           function value at the new point,
C
C     xnew  double precision xnew(n),
C           new point,
C
C     flag  integer,
C           0= convergence with nonmonotone Armijo-like criterion,
C           3= too many function evaluations,
C           5= error in evalf subroutine.

C     PARAMETERS
      double precision gamma
      parameter (gamma=1.0d-04)

C     SCALAR ARGUMENTS
      double precision f,fnew,gtd
      integer maxfc,fcnt,m,n,flag

C     ARRAY ARGUMENTS
      double precision d(n),lastfv(0:m-1),x(n),xnew(n)

C     LOCAL SCALARS
      double precision alpha,atemp,fmax
      integer i,inform

C     EXTERNAL SUBROUTINES
      external evaf

C     INTRINSIC FUNCTIONS
      intrinsic max

C     INITIALIZATION

C     COMPUTE THE MAXIMUM FUNCTIONAL VALUE OF THE LAST M ITERATIONS

      fmax = lastfv(0)
      do i = 1,m - 1
          fmax = max(fmax,lastfv(i))
      end do

C     COMPUTE FIRST TRIAL

      alpha = 1.0d0

      do i = 1,n
          xnew(i) = x(i) + d(i)
      end do

      call evaf(n,xnew,fnew,inform)
      fcnt = fcnt + 1

      if (inform .ne. 0) then
        ! ERROR IN EVALF SUBROUTINE, STOP
          flag = 5
          go to 200
      end if

C     MAIN LOOP

 100  continue

C     TEST STOPPING CRITERIA

      if (fnew .le. fmax + gamma*alpha*gtd) then
        ! NONMONOTONE ARMIJO-LIKE STOPPING CRITERION SATISFIED, STOP
          flag = 0
          go to 200
      end if

      if (fcnt .ge. maxfc) then
        ! MAXIMUM NUMBER OF FUNCTION EVALUATIONS EXCEEDED, STOP
          flag = 3
          go to 200
      end if 

C     DO AN ITERATION

C     SAFEGUARDED QUADRATIC INTERPOLATION

      if (alpha .le. 0.1d0) then
          alpha = alpha/2.0d0

      else
          atemp = (-gtd*alpha**2) / (2.0d0*(fnew-f-alpha*gtd))
          if (atemp .lt. 0.1d0 .or. atemp .gt. 0.9d0*alpha) then
              atemp = alpha/2.0d0
          end if
          alpha = atemp
      end if

C     COMPUTE TRIAL POINT 

      do i = 1,n
          xnew(i) = x(i) + alpha*d(i)
      end do

C     EVALUATE FUNCTION

      call evaf(n,xnew,fnew,inform)
      fcnt = fcnt + 1

      if (inform .ne. 0) then
        ! ERROR IN EVALF SUBROUTINE, STOP
          flag = 5
          go to 200
      end if

C     ITERATE

      go to 100

C     STOP

 200  continue

      end
