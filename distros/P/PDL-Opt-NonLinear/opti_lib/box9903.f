
c*********************************************************************
c*                       SUBROUTINE BOX9903                          *
c*********************************************************************
c      Written: March 1999
c
c      Modifications:
c      January 16, 2002: add missing declaration in subroutine grad
c      April 14, 1999: parameter ftol was added .
c      May 7, 2001: forbidden L(i) = U(i)
c
c      Developed by the Optimization Group at the State University of
c                            Campinas 
c
c                     Date: March 1999      (99/03)
C
C          This subroutine solves the problem
C
C                      Minimize f(x)
c                      s. t. h(x) = 0
c                            A x  = b                          (1)
C                           l <= x <= u                        
c
c       where 
c
c                     f: \R^n ---> \R
c
c                     h: \R^n ----> \R^{nonlc}
c
c                     A \in \R^{m x n}
c
c       and f and h are differentiable functions. That is to say, the 
c       smooth nonlinear programming problem with m linear equality 
c       constraints, nonlc nonlinear equality constraints, 
c       and bounds on the variables. 
c
c          This code was written with the aim of dealing with large-scale
c       problems, for this reason it does not impose storing or factorization
c       of matrices of any kind. 
c          The outer algorithm for solving (1) is the Augmented Lagrangian
c       method. Namely, at each outer-iteration the following 
c       box-constrained problem is solved       
c
c                            
c                          Minimize   L(x) 
c                                                          (2)
c                      subject to  l <= x <= u
c          
c
c                             where L(x) =
c
c                         f(x) +  mu^T h(x) + 
c
c              + (1/2) Sum_{i=1}^{nonlc} ra(i) [h(x)]_i^2 +
c          
c             +  lambda^T (A x - b) + (ro/2) ||A x - b||_2^2
c
c      L(x) is called ``the Augmented Lagrangian'' associated to (1).
c
c

c
c         Therefore, mu is the vector of Lagrange multipliers associated
c      to nonlinear equality constraints, lambda is the vector of Lagrange
c      multipliers associated to linear constraints, ra is a vector of
c      penalty parameters associated to nonlinear equality constraints,
c      and ro is  a single  penalty parameter associated to linear constraints.
c
c         A description of the method used in box9903 can be found in
c
c       N. Krejic, J. M. Martinez, M. P. Mello and E. A. Pilotta
c       [1999]: "Validation of an Augmented Lagrangian algorithm with a
c       Gauss-Newton Hessian approximation using a set of hard-spheres
c       problems", to appear in 
c       Computational Optimization and Applications.
c
c
c
c         For solving (2) at each outer iteration it is used the subroutine
c      BOX, enclosed within this piece of software. BOX solves (2) using
c      the method described in:
c
C       A. Friedlander, J. M. Martinez and S. A. Santos [1994]: "A new
C       trust-region strategy for box-constrained minimization", 
C       Applied Mathematics and Optimization  30 (1994) 235-266.
c
c
c          At each outer iteration BOX will be called trying to find 
c       a minimizer of (2) up to the precision eps (or epsd).
c
c
c          The main work performed by box9903 consists in calling BOX 
c       and modifying the penalty parameters ro (associated to the 
c       linear constraints) and ra (associated to the nonlinear
c       equality constraints). Moreover, the Lagrange multipliers mu 
c       (associated to the nonlinear equality constraints), and lambda 
c       (associated to the linear constraints) are also updated in box9903
c       at each outer iteration. 
c
c*******************************************************************
c*                                                                 *
c*                                                                 *
c*                      PARAMETERS OF BOX9903                      *
c*                                                                 *
c*                                                                 *
c*******************************************************************
c
c       n: number of variables.
c   
c       m: number of linear constraints.
c
c       nonlc: number of nonlinear equality constraints.
c
c       roinic: (input) if linear constraints are present (m > 0) you must 
c       set roinic equal to the initial value that you wish for 
c       the penalty parameter associated to the linear constraints.
c
c       rainic: (input) is a vector of nonlc positions. If nonlc = 0
c       you must dimension rainic with only one position.  If nonlinear 
c       equality constraints are present (nonlc > 0) you
c       must set rainic equal to the initial values that you wish for 
c       the penalty parameters associated to nonlinear constraints.
c
c       ra: (auxiliar) is a vector of nonlc positions. If nonlc = 0
c       you must dimension ra with only one position. If nonlinear 
c       equality constraints are present (nonlc > 0) ra is used by 
c       this subroutine to store the penalty parameters associated to
c       each nonlinear equality constraint. 
c
c       facro: (input) if linear constraints are present (m > 0) you must
c       set facro >= 1 equal to the factor by which you want to multiply
c       penalty parameter ro after each outer iteration.
c       
c       facra: (input) if nonlinear equality constraints are present 
c       (nonlc > 0) you must set facra >= 1 equal to the factor by which 
c       you want to multiply the penalty parameters ra(i) after
c       each outer iteration.
c
c       indivi: (input) if you set indivi = 1, penalty parameters
c       associated to each nonlinear equality constraint 
c       will be increased separately. 
c       If indivi = 0, penalty parameters associated to
c       nonlinear equality constraints will be increased 
c       together, so that the process will work as if it existed only 
c       one penalty parameter associated to nonlinear equality constraints.
c
c       epslin: (input) if linear constraints are present you must
c       set epslin equal to the level of feasibility that you want associated
c       to these constraints. In other words, a point x will be considered
c       ``feasible'' with respect to linear constraints when
c
c                       ||A x - b||_\infty <= epslin
c
c       epsnon: (input) if nonlinear equality constraints 
c       are present you must set epsnon equal to the level of feasibility 
c       that you want associated to these constraints.
c       In other words, a point x will be considered
c       ``feasible'' with respect to nonlinear equality constraints when
c
c                          || h(x) ||_\infty <= epsnon
c
c       ratfea: (input) If the feasibility at the new outer iteration
c       is better than ratfea*(the feasibility at the previous iteration)
c       the penalty parameter will not be increased. ratfea must be greater
c       than or equal to zero. 
c
c       epsinic: (input) This is the convergence criterion that will be
c       used by Box at the first outer iteration. 
c
c	epsdiv: (input) If epsinic > epsfin, the convergence criterion
c       used by Box at successive outer iterations is the previous one
c       over epsdiv. For example, if Box used eps = 10^{-2} at the outer
c       iteration kon, it will use eps/epsdiv at the following one.
c       However if the new eps is less than epsfin, it is replaced by
c       epsfin. epsdiv must be greater than 1.
c
c       epsfin: (input) This is the convergence criterion that will
c       be used by Box at the final outer iteration. 
c       If you set epsinic = epsfin
c       the same convergence criterion will be used at all the iterations.
c
c
c       maxout: (input) maximum number of outer iterations (calls to BOX).
c
c       iprint: (input) parameter by means of which you can say what
c               you want to be printed automatically by box9903, both
c               in the screen and in a file (unity 10). If iprint < 0,
c               nothing will be printed. If iprint = 0, only information
c               at the initial point and at the final point will be 
c               printed. In all the other cases, information will also
c               be printed every iprint outer iterations. 
c
c       konout: (output) effective number of outer iterations performed.
c       konint: (output) total number of inner iterations (iterations of BOX)
c       nefint: (output) total number of evaluations of f(x)
c       itqint: (output) total number of quacan iterations
c       mvpint: (output) total number of matrix-vector products performed 
c               in quacan
c
c       hresan: (input) auxiliar double precision vector of at least 
c               nonlc positions (1 position if nonlc = 0)
c
c       ierla: output parameter that indicates what happened in the 
c        execution of box9903. If ierla = 0, a feasible point, according
c        to the prescribed tolerances epslin and epsnon, has been found.
c        If there are no constraints in the problem ierla will be necessarily
c        equal to 0. The final diagnostic concerning the execution of
c        box9903 must be complemented looking at the BOX output parameter
c        istop. In fact, if istop = 0 and ierla = 0 you can guarantee
c        that a point that satisfies first-order optimality
c        conditions of (1) has been found. Other situations are doubtful.
c        If ierla = 1, the allowed number of outer iterations (calls to
c        BOX) has been exhausted without achieving feasibility. 
c   
c      ilag: (input) can take the values 0 and 1. If ilag = 0 the estimates
c        of the  Lagrange  multipliers at each iteration are zero. In
c        other words, in this case one is using a pure  penalty method.
c        If ilag = 1 first order Lagrange multipliers are estimated 
c        at each outer iteration.
c
c      iguess: (input) can take the values 0 and 1. If iguess = 1
c        this means that you have a procedure to guess a good approxima-
c        tion to the solution of the quadratic problem that must be 
c        solved at each iteration of BOX. In this case, you must write
c        the way to calculate your guess in the subroutine guess. More
c        about this parameter and subroutine guess in the comments of
c        the subroutine BOX.
c
c      x: double precision vector with n positions. On input, initial
c         approximation to the solution. On output, best solution obtained.
c
c      l, u : on input, double precision vectors that define the
c             bounds of Problem (1).
c
c      hres: double precision auxiliar vector with at least nonlc positions.
c            On output it contains the values of h(x) mentioned in (1).
c      
c      res: double precision auxiliar vector with m positions.
c           On exit, when m is not 0, residual vector A x - b.
c
c      grad:  double precision auxiliar vector with n positions.
c           On exit, g is the gradient of L (the augmented Lagrangian)
c           at the final point.
c
c      fx:  on output, functional value f(x).
c
C
C     iprbox : control for printing in subroutine BOX. If iprbox< 0 nothing 
c       is printed in BOX. If iprbox = 0, only a
C       final summary is printed. If iprbox > 0, information every iprbox
C       iterations is printed. 
C
c
c
C     mu: auxiliar double precision input vector with nonlc components,
c     (1 component if nonlc = 0)
c     that contributes to define the objective function. It stores the
c     Lagrange multipliers associated to nonlinear equality constraints.
c
c     lambda: auxiliar double precision input vector with m components
c     (1 component if m = 0)
c     that contributes to define the Augmented Lagrangian. It stores the
c     Lagrange multipliers associated to linear equality constraints.
c
c
c---------------------------------------------------------------------------
c
c             SUBROUTINES phi AND MAPRO, THAT DEFINE Phi(x),     
c
c
c              ITS GRADIENT, AND ITS HESSIAN APPROXIMATION
c
c
C---------------------------------------------------------------------------
c
C       The user must provide a subroutine named phi for computing
C       the function value 
c
c                             Phi(x) =
c
c                
c                     =  f(x) +  mu^T h(x) + 
c
c              + (1/2) Sum_{i=1}^{nonlc} ra(i) h_i(x)^2 +
c          
c       the gradient of Phi(x) and the information relative to the 
c       Hessian approximation of Phi(x).
c
C       The calling sequence of phi is
C
C  call phi (n, nonlc, x, mu, ra, flagra, fx, grad, hres, hess, inhess, modo )
C
C       where n is the number of variables, nonlc is the number of
c       components of h, 
c       x is the point where the  function is calculated within phi, 
c       mu and ra are the other input parameters necessary
c       for computing Phi(x).
c       As output, phi must produce flagra (Phi(x)), fx (f(x)), 
C       grad, the gradient of the function Phi computed at x, hres 
c       (the nonlinear vector of residuals  h(x)).
c       Finally, hess and inhess inhess are arrays that can contain 
c       the information relative to the Hessian approximation. 
C       You can choose the name for the subroutine phi. For this
C       reason, phi is a parameter of box9903. In the calling
C       program, the name actually used must be declared EXTERNAL. 
C       If modo = 1, phi must compute ONLY the function 
c       values flagra and fx and the
c       vector of nonlinear residuals hres,
c       which, of course, are by-products of the computation of the 
c       function value flagra.
C       If modo = 2, phi must compute ONLY the gradient at
c       the point x and the information relative to the Hessian.
c       Now, you can take
c       advantage of the common calculations to function and gradient-
c       Hessian learning that a call to phi with modo=2 is always
c       preceeded, in BOX, by a call to phi with modo=1 at the same
c       point. So, you can prepare information inside phi in such a way
c       that calculations for modo=2 are already done, and you do not
c       need to begin from scratch. In particular, for computing the
c       gradient, you will need the nonlinear residuals hres.
c       So, you can use it freely.
C       You can choose the data structure for the Hessian
c       information provided that it fits in the arrays inhess and 
c       hess. This information must be compatible with the coding of
c       user supplied subroutine mapro, commented below.
c       In previous versions of BOX it was assumed that the communication
c       of Hessian information between phi and mapro was coded through
c       COMMON statements. We think that passage through parameters is
c       less prone to errors, so we decided to introduce the new 
c       parameters hess and inhess in 1995. However, if you
c       find easier to make the communication by COMMON, you can do it
c       disregarding the existence of hess and inhess. However, do not
c       forget to dimension hess and inhess.
c
c       Helping your memory:
c
c   The gradient of the objective function Phi(x) considered here is
c
c  \nabla f(x) +  Sum_{i=1}^{nonlc} [mu(i) + ra(i) h_i(x)] \nabla h_i(x) 
c
c
c   The Hessian is
c
c  \nabla^2 f(x) + Sum_{i=1}^{nonlc} ra(i) \nabla h_i(x) \nabla h_i(x)^T +
c
c     + Sum_{i=1}^{nonlc} [mu(i) + ra(i) h_i(x)] \nabla^2 h_i(x)
C
c
C       You must also provide the subroutine mapro. As in the case
C       of phi , you can choose the name of this subroutine, which, for
C       this reason, must be declared EXTERNAL in the calling program.
C       mapro is called only from quacan. As a result, it is also
C       a parameter of quacan, and it is declared EXTERNAL in BOX 
C       subroutine. The calling sequence of mapro is
C
C               call mapro (n, nind, ind, u, v, hess, inhess )
C       
C       where n (the number of variables) and u (a double precision vector
C       of n positions) are the main inputs, and v, a double precision
c       vector of n positions is the output. v must be the product H * u,
c       where H is the current Hessian approximation of the function Phi(x).
c       That is, H is the last  computed Hessian approximation of Phi(x)
c       within the subroutine phi. 
c       Therefore, mapro must be coded in such a way that the structure 
c       given for this matrix within phi is compatible with formulae for
c       the product.
c       Moreover, if nind < n (both are input parameters), the integer vector
c       ind, with nind positions, contains the indices where the input
c       u is different from zero. So, you can take advantage of this 
c       information to write the matrix-vector product, but if you do
c       not know how to do it, simply ignore nind and ind and write the
c       matrix vector product as if u were a dense vector. The algorithm
c       will be the same, but taking advantage of nind and ind makes it
c       faster. 
c       Many times, you will find the task of coding the information
c       relative to the Hessian very cumbersome. You can use a 
c       ``directional finite difference'' version of mapro instead of
c       products with true Hessians. The idea is that, at the current
c       point x, the product H u is the limit of 
c 
c               [Gradient(x + t u) - Gradient(x) ] / t
c
c       Using this directional derivative idea, you can code mapro 
c       passing, within hess, the current point x and the current 
c       gradient g to mapro. Then, you use, say, 
c
c       t = max ( 1.d-20, 1.d-8 ||x||_\infty ) / || d ||_\infty
c
c       provided that d \neq 0, of course.
c
c      So, in this case you evaluate the Gradient 
c      at the auxiliary point x + t u and 
c      finally, you use the quotient above to approximate H u. There
c      are some risks using this device, but you can try.
c
C--------------------------------------------------------------------------
c                       PARAMETERS  hess AND inhess
C--------------------------------------------------------------------------
C
C      From the point of view of box9903, hess and inhess are two auxiliar
c      arrays. hess is double precision and inhess is integer. They can
c      be used in the subroutines phi and mapro to transmit Hessian information
c      between them (from phi to mapro) as explained above. The
c      number of positions reserved to hess and inhess must be sufficient
c      for the information that you want to transmit.
c
c----------------------------------------------------------------------------
c
c                         SUBROUTINE GUESS
c
c----------------------------------------------------------------------------
C
C     At each iteration of BOX, bound-constrained quadratic problems of
c     the form
c
c          Minimize grad(x^k) d + (1/2) d^T B_k d
c          subject to lint <= d <= uint
c
c     are solved by the subroutine Quacan. Here, B_k is an approximation
c     of the Hessian of the objective function used in BOX (the whole
c     augmented Lagrangian). Sometimes, experienced users know how to
c     compute good approximations to the solution of this subproblem,
c     independently of Quacan. In this case, the user sets the input 
c     parameter iguess equal to 1. In fact, in that case, Quacan is going
c     to take the approximation ``computed by the user'' as initial appro-
c     ximation for its own job. When you set iguess = 1, you must code
c     your way to compute the initial approximation to the solution of
c     the bound-constrained quadratic subproblem in the subroutine guess.
c     (In fact, since the name of the subroutine is a parameter, you can
c     give other name to the subroutine, as is the case with Phi and Mapro.
c     Consequently, you must also declare external the name of this subroutine
c     in your main code.)
c     The calling sequence of guess must be:
c
c     call guess(n, x, grad, ro, ra, lambda, mu, lint, uint, d)
c
c     where you must consider that n is the number of variables, x is
c     current point in the procedure commanded by BOX, grad is the gra-
c     dient of the objective function (Augmented Lagrangian) at x, lint
c     is the vector of lower bounds for d, uint is the vector of upper
c     bounds of d, ro is the penalty parameter associated to linear 
c     constraints, ra is the vector of penalty parameters associated
c     to nonlinear equality constraints, lambda is the vector
c     of multipliers associated to linear constraints, mu is the
c     vector of multipliers associated to nonlinear equality constraints,
c     Finally, d (the output) is the approximate solution to 
c     the bound-constrained quadratic subproblem computed by guess.
c     All real parameters in guess must be double precision. Probably,
c     for computing your approximation you could need additional information
c     on the current point. In this case, use common statements to make
c     the communication between Phi and Guess. Probably, all the relevant
c     information necessary for Guess has already been computed in Phi,
c     with modo=2. 
c     Even if you are setting iguess=0, you must include a subroutine
c     called guess in your main stack but, in this case, it will not be
c     called by BOX, so, it can consist only of the statements return
c     and end in order of not to disturb the compilation. It is enough,
c     in the case ``iguess=0'', that you include the statements
c                             subroutine guess
c                             return
c                             end
c
c
c-------------------------------------------------------------------------
c
c     PARAMETERS THAT DEFINE THE LINEAR AUGMENTED LAGRANGIAN TERM
C
c                            
C           lambda^T (A x - b) + (ro/2) || A x - b ||^2 
c
c
c
c     m, lambda, ro, ispar, nelem, inda, a, b are the input
c        parameters that define the augmented Lagrangian term.
c
c      m : number of rows of the matrix A. Set m=0 if there is no 
c          Lagrangian term at all
c
c
c      lambda : vector of m double precision positions given in the 
c          definition of the objective function L.
c
c      ro : real*8 number given in the definition of L
c
c      ispar : input integer parameter that can take the value 0 or 1
c              If ispar = 0, this means that the m x n matrix A is stored
c              in the array a columnwise, that is a(1,1), a(2,1), a(3,1),
c              ... a(m,1), a(1,2), a(2,2),...,a(m,2)...
c              You can use ispar=0 when there is not advantage on taking
c              into account sparsity of A. In other words, when you judge
c              that A is dense.
c              If ispar=1, this means that you give only the nonzero elements
c              of A, in the way explained below.
c
c      nelem : this input parameter is used only when ispar = 1. It
c              is the number of ``nonzero'' elements that you are reporting
c              for the matrix A.
c
c      inda : this input parameter is used only when ispar = 1. In
c             this case, it is an integer nelem x 2 array where you
c             must store, in any order, the pairs (i , j) such that the
c             corresponding element a_{ij} of the matrix A is different
c             from zero. 
c
c      a    :  If ispar=0, this array contains the entries of the matrix
c              A, stored columnwise (see ispar above). If ispar =1, this
c              array contains the nonzero elements of A in such a way
c              that a(k) = a_{ij} when the row k of inda is (i, j).
c
c      b    :  real*8 vector of m positions, mentioned in the definition
c              of L(x) above.
c
c ----------------------------------------------------------------------------
c             A SET OF PARAMETERS USED ONLY IN THE SUBROUTINE BOX
c ----------------------------------------------------------------------------

C
C     accuracy : accuracy demanded for quacan at its first call
c       within a box-iteration. The user must give this parameter belonging
C       to (0,1). We recommend to set accuracy = 0.1. If the
c       objective function f is quadratic we recommend accuracy=1.d-8
c       so that most the work will be executed by quacan. A small 
c       accuracy is also desirable if the problem is badly scaled.
c	Moreover, if the number of variables is small we prefer accuracy
c       very small since in this case the quadratic solver is not very
c       costly.
c
C     acumenor : accuracy demanded for quacan at subsequent calls
c       (not the first) 
c       within a box-iteration. The user must give this parameter belonging
C       to (0,1). We recommend to set acumenor=0.5. 
c	If the number of variables is small we prefer acumenor
c       very small since in this case the quadratic solver is not very
c       costly.
c
c     relarm, absarm: two input parameters that define when the trial
c       point is accepted. Namely, if Pred < 0 is the value of the approxi-
c       mating quadratic at its approximate minimizer and x+ is the corres-
c       ponding trial point, x+ is accepted as new point when
c
c              L(x+) \leq  L(x) +  max ( relarm * Pred,  -absarm)
c
c       We recommend relarm = 0.1, absarm = 1.d-6
c
c        
c
C     epsd : input parameter representing a tolerance for the trust
C       region radius used in BOX. See usage in the description of 
c       (istop = 4) below.
C       When BOX is unable to produce a decrease even with a trust
C       region of size epsd, this possibly  means that we are very close  
C       to a solution, which was not detected by the convergence criterion
C       based on the projected gradient because, perhaps, that stopping
c       parameter  was given  excessively small. 
c       Roughly speaking, BOX  returns because of the
C       (istop = 4) criterion, when the quadratic model restricted
C       to a ball of radius epsd is unable to produce a decrease of the
C       function. This is typical when a local minimizer occurs, but we
C       must be careful. We recommend to set epsd = 1.d-8. However, warning!
c       this is a dimensional parameter, you must take into account
c       the scaling (unit measures) of your problem. Roughly speaking,
c       epsd shoud be a NEGLIGIBLE DISTANCE in the x-space.
C
C     nafmax : Maximum allowed number of function evaluations at each
c       call of BOX. See  description of (istop = 2) below.
C
C     itmax : Maximum allowed number of iterations at each call of BOX.
C       See description of (istop = 3) below.
C
C     par : This parameter is used to define the size of the new trust
C       region radius and must be given by the user belonging to (1,10).
C       We recommend to set par = 4. See usage in the description of
C       deltamin below.
c
C     delta0 : This input parameter is the initial trust region radius at
C       the beginning of iteration zero. Warning! Delta0 is dimensional.
c       It should represent the radius of a ball centered on the initial
c       point where you reasonably expect to be the solution.
C
C     deltamin : This input parameter allows the subroutine to define
C       the trust region radius. In fact, at the beginning of an 
C       iteration, the trust region radius is defined by BOX to be 
c       not less than deltamin. Due to this choice, the
C       trust region radius can inherit more or less information from the 
C       previous iteration, according to the size of deltamin. deltamin can 
C       be a fraction of the diameter of the problem (1), provided that 
C       there are no artificial bounds. We recommend deltamin=delta0/100.
C
C     istop : This output parameter tells what happened in the last call
C       subroutine BOX (that is to say, the last outer iteration),
c       according to the following conventions:
C       istop = 0   ->  Convergence : 
C                       ||projected gradient||_\infty \leq eps.
C       istop = 1   ->  Convergence : 
C                       L(x) \leq ftol
C       istop = 2   ->  It is achieved the maximum allowed number of
C                       function evaluations (nafmax).
C       istop = 3   ->  It is achieved the maximum allowed number of
C                       iterations (Itmax).
C       istop = 4   ->  Strangled point, i.e. trust region radius less
C                       than epsd.
c
C       istop = 5   ->  Data error. A lower bound is greater than an
C                       upper bound.
c
c       istop = 6   ->  Some input parameter is out of its prescribed
c                       bounds
c
C       istop = 7   ->  The progress (L(x_k) - L(x_{k-1})) in the last 
C                       iteration is less than bont * (the maximum
C                       progress obtained in previous iterations)
c                       during kbont consecutive iterations.
c
C       istop = 8   ->  The order of the norm of the continuous 
c                       projected gradient did not change 
c                       during kauts consecutive
c                       iterations. Probably, we are asking for an 
c                       exagerately small norm of continuous projected
c                       gradient for declaring convergence.
c
C     bont, kbont : This parameters play the same role as dont and kdont do
c     for quacan. We also suggest to set bont = 0.01 together with kbont = 5.
C
c    kauts : If the order of the norm of the current 
c              continuous projected gradient did not change during 
c              kauts consecutive iterations the execution
c              stops with istop = 8. Recommended: kaustky = 10. In any
c              case kauts must be greater than or equal to 1. 
c
c     You must also set the following input quacan parameters:
c
c     dont : Positive number, less than 1, used for the second convergence
c       criterion by quacan, according to the description above. See
c       also the comments of the subroutine quacan.
c
c    eta: On input, number belonging to (0, 1) .
c        If eta is close to 1, faces are fully exploited before abandoning
c        them. If eta is close to 0, abandoning faces is frequent. We
c        recommend eta = 0.9.
c
c    factor: On input, real number greater than 1 (we recommend factor=5)
c           intended to improve the current trial guess through extrapo-
c           lation procedures. It is used in the subroutine Double. See
c           its comments.
c   mitqu: maximum number of iterations allowed on each call to quacan.
c   maxmv: maximum number of matrix-vector products allowed on each call
c          to quacan.
c    ipqua: printing parameter of quacan. If ipqua < 0, nothing is printed.
c                             If ipqua = 0, only a final summary is printed
c                             of each call of quacan.
c                             Otherwise, information on quacan
c                             iterations are  printed every
c                             ipqua iterations.
c
c
c     lint, uint, s, gq, gc, xn, gn, d: auxiliar double
c                    precision vector with n positions.
c     bd: auxiliar vector that must be dimensioned with n+1 positions
c       when m = 0 an with at least 2n+m real*8 positions when m > 0
c
c     ingc, infree: integer auxiliar vectors of n positions.
c
c ----------------------------------------------------------------------------
c             END OF ``A SET OF PARAMETERS USED ONLY IN THE SUBROUTINE BOX''
c ----------------------------------------------------------------------------

c
c      For consults relative to the use of this subroutine please contact:
c
c                      J. M. Martinez
c                     IMECC - UNICAMP
c                        C.P. 6065
c                    13081-970 Campinas SP
c                          Brazil
c                E-mail: martinez@ime.unicamp.br
c                   

	subroutine box9903 (n, m, nonlc, roinic, ra, rainic, indivi,
     *  facro, facra, ilag, iguess, epslin, epsnon, ratfea,
     *  maxout, konout, konint, nefint, itqint, mvpint, ierla, iprint, 
     *  x, l , u, fx, hres, hresan, res, grad,
     *  accuracy, acumenor, relarm, absarm, epsinic, epsdiv, epsfin,
     *  epsd, ftol, nafmax, itmax, par, delta0, deltamin, istop,
     *  bont, kbont, kauts, dont, kdont, eta, factor, 
     *  mitqu, maxmv, phi, mapro, guess, hess, inhess, iprbox,
     *  ipqua, lint, uint, s, gq, gc, bd, xn, gn, d, ingc, infree,
     *  mu, lambda,  ispar, nelem, inda, a, b)

	implicit double precision(a-h,o-z)
	external phi, mapro, guess
	double precision l(n), lint(n), lambda(*), mu(*)
	dimension x(n), u(n), grad(n), hess(*),  uint(n)
        dimension s(n), gq(n), gc(n), bd(*), xn(n), gn(n)
	dimension d(n), ingc(n), infree(n), inda(*)
	dimension a(*), b(*)
	dimension res(*), hres(*)
	dimension inhess(*)
	dimension rainic(*), ra(*)
	dimension hresan(*)


	do i = 1, n
	if(l(i).ge.u(i)) then
	istop = 6
	write(*, *)' Lower bound',i,' not smaller than upper bound'
	write(10, *)' Lower bound',i,' not smaller than upper bound'
	return
	endif
	if(x(i).lt.l(i)) x(i) = l(i)
	if(x(i).gt.u(i)) x(i) = u(i)
	end do
	

c
	if(iprint.ge.0)then
	n10 = min0(n, 10)
	m10 = min0(m, 10)
	nlc10 = min0(nonlc, 10)
	endif
c
c       We set the initial vectors of multipliers equal to zero
c
c       We set the initial penalty parameters equal to the ones 
c       indicated by the user
c
	if(nonlc.gt.0)then
	do  i = 1, nonlc
	ra(i) = rainic(i)
	mu(i) = 0.d0
	end do
	endif

	if(m.gt.0) then
	do  i =1,m
	lambda(i) = 0.d0
	end do
	ro = roinic
	endif

c
c       konout is the counter of outer iterations
c
        konout = 0
c
c
c      Initialization of counters of inner iterations, function evaluations,
c      quacan-iterations and matrix-vector products
c
	konint = 0
	nefint = 0
	itqint = 0
	mvpint = 0
c
c      Evaluations at the initial point
c

        call phi (n, nonlc, x, mu, ra, flagra,
     *           fx, grad, hres, hess, inhess, 1 )


	if(m.gt.0) call pena(n, x, flagra, grad, res, 
     *   m, ilag, lambda, ro, ispar, nelem, inda, a, b, bd, 1)


	if(nonlc.gt.0) then
	hnor = 0.d0
	do i = 1, nonlc
	hnor = dmax1(hnor, dabs(hres(i)))
	hresan(i) = dabs(hres(i))
	end do	
	hnoran = hnor
	endif

	if(m.gt.0) then
	anor = 0.d0
	do i = 1, m
	anor = dmax1(anor, dabs(res(i)))
	end do
	anoran = anor
	endif


	if(iprint.ge.0) then 
	write(10,*)
	write(*,*)
	write(10,*)'                           OUTPUT OF BOX9903'
	write(10,*)
c
	write(*,*)'                            OUTPUT OF BOX9903'
	write(*,*)
	write(*,*)

	call imprimir (n10, m10, nlc10, nonlc, 
     *     konout, x, istop, konint, nefint, eps, 
     *     itqint, mvpint, anor, hnor, 
     *     ra, ro, mu, lambda, flagra, fx)

	endif
c

c
c   At the first call to box, we set eps = epsinic
c
	eps = epsinic


10	call box (n, x, l , u, iguess, flagra, fx, hres, res,
     *  grad, accuracy, acumenor, relarm, absarm, eps, epsd, ftol,
     *  nafmax, itmax, kont, naf, iqua, mvp, par, 
     *  delta0, deltamin, istop, bont, kbont, kauts,
     *  dont, kdont, eta, factor, 
     *  mitqu, maxmv, phi, mapro, guess, hess, inhess, iprbox, ipqua, 
     *  lint, uint, s, gq, gc, bd, xn, gn, d, ingc, infree,
     *  nonlc, mu, ra, 
     *  m, lambda, ro, ispar, nelem, inda, a, b)





c
c     Increment counters of outer iterations, 
c     inner (BOX)-iterations, evaluations, quacan-iterations
c     and matrix-vector products
c
	konout = konout + 1
	konint = konint + kont
	nefint = nefint + naf
	itqint = itqint + iqua
	mvpint = mvpint + mvp
c


	hnor=0.d0
	if(nonlc.gt.0)then
	do  i=1,nonlc
	hnor=dmax1(hnor, dabs(hres(i)))
	end do
	endif


	anor=0.d0
	if(m.gt.0)then
	do  i =1,m
	anor = dmax1(anor, dabs(res(i)))
	end do
	endif


c   If ilag = 1, update the Lagrange multiplier estimators
c
	if(ilag.eq.1)then

	if(nonlc.gt.0)then

	do  i=1,nonlc
	mu(i)=mu(i) + ra(i) * hres(i)
	end do

	endif
c
c
	if(m.gt.0)then

	do  i=1,m
	lambda(i) = lambda(i) + ro * res(i)
	end do

	endif

	endif

c   Printing session

	if(iprint.gt.0. and. mod(konout, iprint).eq.0)then
	call imprimir (n10, m10, nlc10, nonlc, 
     *     konout, x, istop, konint, nefint, eps, 
     *     itqint, mvpint, anor, hnor, 
     *     ra, ro, mu, lambda, flagra, fx)
	endif


c    Terminate if feasibility was achieved
	if(eps.le.epsfin) then
	if((hnor.le.epsnon.or.nonlc.le.0).and.
     *   (anor.le.epslin.or.m.eq.0))then
	ierla = 0
	if(iprint.lt.0)return
	write(10,*)
	write(10,*)' Feasibility was achieved.'
	write(*,*)
	write(*,*)' Feasibility was achieved.'
	if(iprint.gt.0. and. mod(konout, iprint).eq.0)return
	call imprimir (n10, m10, nlc10, nonlc, 
     *     konout, x, istop, konint, nefint, eps, 
     *     itqint, mvpint, anor, hnor, 
     *     ra, ro, mu, lambda, flagra, fx)
	return
	endif
	endif

c     Terminate if number of allowed outer iterations is exhausted
	if(konout.ge.maxout) then 
	ierla = 1 
	if(iprint.lt.0)return
	write(10,*)
	write(10,*)' Maximum number  of outer  iterations achieved.'
	write(*,*)
	write(*,*)' Maximum number of outer iterations achieved.'
	if(iprint.gt.0. and. mod(konout, iprint).eq.0)return
	call imprimir (n10, m10, nlc10, nonlc, 
     *     konout, x, istop, konint, nefint, eps, 
     *     itqint, mvpint, anor, hnor, 
     *     ra, ro, mu, lambda, flagra, fx)
	return
	endif
c
c     Updating penalty parameters corresponding to
c     the nonlinear equality constraints
c
	if(nonlc.gt.0)then
         if(indivi.eq.1)then

	do  i = 1, nonlc
c   Update, separately, penalty parameters corresponding to nonlinear
c   constraints
c   Increase the penalty parameter
c   only if feasibility was not greatly improved
          if(dabs(hres(i)) .gt. ratfea * hresan(i)) then
            ra(i) = facra * ra(i)
            endif

c   Save the vector of constraints at the present iteration, to be used
c   in the following one
	   hresan(i) = dabs(hres(i))
	end do

	else

c   Case indivi .ne. 1. All the nonlinear penalty parameters are 
c   updated together

	if(hnor.gt. ratfea * hnoran) then
c   At subsequent iterations update the penalty parameter if feasibility
c   was not greatly improved
	do  i=1,nonlc
	ra(i) = facra * ra(i)
	end do
	endif
c   Save the norm of the vector of constraints to be used at subsequent
c   iterations
	hnoran = hnor	
	endif 
	endif

	if(m.gt.0)then
c   Update the penalty parameter ro if we are at the first iteration or
c   if linear feasibility was not greatly improved
	if(anor .gt. ratfea * anoran) then
	ro = facro * ro
	endif
c   Save the norm of the vector of linear constraints, to be used at
c   subsequent iterations
	anoran = anor
	endif
c
c   Compute the convergence parameter that will be used by Box at
c   the next outer iteration, as an interpolation between epsinic and
c   epsfin
c
	eps = dmax1(eps/epsdiv, epsfin)
	
c   Perform a new outer iteration
	goto 10

	end




	subroutine imprimir(n10, m10, nlc10, nonlc, 
     *    konout, x, istop, konint, nefint, eps, 
     *    itqint, mvpint, anor, hnor, 
     *    ra, ro, mu, lambda, flagra, fx)

c    Printing subroutine of box9903

	implicit double precision (a-h, o-z)
	dimension x(*)	
	double precision lambda(*), mu(*), ra(*)

	write(10,*)
	write(10,*) ' Outer Augmented Lagrangian iteration :', konout
	write(10,*) ' (First 10) components of the current point:'
	write(10,*) (x(i), i=1, n10)

	write(*,*)
	write(*,*) ' Outer Augmented Lagrangian iteration :', konout
	write(*,*) ' (First 10) components of the current point:'
	write(*,*) (x(i), i=1, n10)


	if(m10.gt.0)then
	if(konout.ne.0) then
	write(10,*) ' (First 10) components of lambda:'
	write(10,*) (lambda(i), i=1, m10)
	write(10,*) ' Penalty parameter used for linear constraints:',
     *     ro
	write(*,*) ' (First 10) components of lambda:'
	write(*,*) (lambda(i), i=1, m10)
	write(*,*) ' Penalty parameter used for linear constraints:',
     *     ro
	endif
	endif

	if(nlc10.gt.0)then
	if(konout.ne.0) then

	write(10,*) ' (First 10) nonlinear equality multipliers:'
	write(10,*) (mu(i), i=1, nlc10)
	write(10,*) ' Penalty parameters used for nonlinear equality', 
     *  ' constraints (first 10):'
	write(10,*) (ra(i), i=1, nlc10)


	write(*,*) ' (First 10) nonlinear equality multipliers:'
	write(*,*) (mu(i), i=1, nlc10)
	write(*,*) ' Penalty parameters used for nonlinear equality', 
     *  ' constraints (first 10):'
	write(*,*) (ra(i), i=1, nlc10)

	ramax = 0.d0
	ramin = ra(1)
	do  i = 1, nonlc
	ramin = dmin1(ramin, ra(i))
	ramax = dmax1(ramax, ra(i))
	end do

	write(10,*)' Maximum nonlinear equality penalty parameter',
     *   ' used:',ramax
	write(10,*)' Minimum nonlinear equality penalty parameter',
     *    ' used:',ramin


	write(*,*)' Maximum nonlinear equality penalty parameter',
     *   ' used:',ramax
	write(*,*)' Minimum nonlinear equality penalty parameter',
     *    ' used:',ramin

	endif
	endif



	if(konout.ne.0) then
	write(10,*)' Diagnostic of BOX at this iteration:', istop
	write(10,*)' Convergence epsilon used in Box:', eps
	write(10,*)' Total number of BOX-iterations:', konint
	write(10,*)' Total number of function evaluations:', nefint
	write(10,*)' Total number of quacan-iterations:', itqint
	write(10,*)' Total number of matrix-vector products:', mvpint


	write(*,*)' Diagnostic of BOX at this iteration:', istop
	write(*,*)' Convergence epsilon used in Box:', eps
	write(*,*)' Total number of BOX-iterations:', konint
	write(*,*)' Total number of function evaluations:', nefint
	write(*,*)' Total number of quacan-iterations:', itqint
	write(*,*)' Total number of matrix-vector products:', mvpint

	endif


	if(m10.gt.0) then
	write(*,*)' Sup norm of A x - b:', anor
	write(10,*)' Sup norm of A x - b:', anor
	endif
	if(nlc10.gt.0) then
	write(*,*)' Maximum violation of nonlinear equality ',
     *  ' constraints :', hnor
	write(10,*)' Maximum violation of nonlinear equality ',
     *  ' constraints :', hnor
	endif

	write(10,*)' Value of the objective function:', fx
	write(10,*)' Value of the augmented Lagrangian function:',flagra

	write(*,*)' Value of the objective function:', fx
	write(*,*)' Value of the augmented Lagrangian function:',flagra



	return
	end




	
C--------------------------------------------------------------------
C                                               February 1997
C

	subroutine box (n, x, l , u, iguess, flagra, fx, hres,
     *  res, grad, accuracy, acumenor, relarm, absarm, 
     *  eps, epsd, ftol, nafmax, itmax, kont, naf, iquatot, mvptot,
     *  par, delta0, deltamin, istop, bont, kbont, kauts,
     *  dont, kdont, eta, factor, mitqu, maxmv, phi, mapro, guess, hess, 
     *  inhess, ipr, ipqua, lint, uint, s, gq, gc, bd, xn, gn, d, ingc,
     *  infree, nonlc, mu, ra, m, lambda, ro, ispar,
     *  nelem, inda, a, b)

C
C       This subroutine solves the problem
C
C                           Minimize L(x)
C                          s.t. l <= x <= u                        (1)
c
c                            where L(x) =
c
c                         f(x) +  mu^T h(x) + 
c
c              + (1/2) Sum_{i=1}^{nonlc} ra(i) [h(x)]_i^2 +
c          
c
c             +  lambda^T (A x - b) + (ro/2) ||A x - b||_2^2
c
c
c       f:\R^n \to \R, h:\R^n \to \R^{nonlc}, 
c       are differentiable, A is an m x n matrix, b \in \R^m,
c       mu \in \R^{nonlc}, ra \in \R^nonlc}, 
c       lambda \in \R^m and ro is a real number.
c
c
c       (That is, L(x) has the form of an augmented Lagrangian of f, for
c       nonlinear constraints of the form h(x) = 0, and 
c       linear constraints of the form A x = b, where A is a matrix of
c       m rows and n columns.) 
C
C       We assume that  l and u are finite n-dimensional bounds.
C
C       The method used to solve (1) is described in
C
C       A. Friedlander, J. M. Martinez and S. A. Santos [1994]: "A new
C       trust-region strategy for box-constrained minimization", 
C       Applied Mathematics and Optimization  30 (1994) 235-266.
c       This algorithm has been modified several times after 1992. 
c
C       The main features of the method are the following:
C
C       a) At each iteration k, the following quadratic approximation
C       of L(x) is considered:
C
C   q(x) = L(x^k) + grad(x^k)^T (x - x^k) + (1/2)(x - x^k)^T B_k (x - x^k)
C       
C       where grad(x) is the gradient of L at x, and B_k is an L-Hessian 
C       approximation (not necessarily positive semidefinite). A sequence
C       of subproblems of the form
C
C                      Minimize q(x) s.t. box_k                        (2)
C
C       is solved  approximately until the solution of (2) satisfies a  
C       decrease condition. Then this solution is chosen as x^{k+1}.
C       The size of box_k depends on the natural bounds of the
C       problem , as well as on a trust-region size. The trust region
C       size is decreased each time the sufficient decrease condition 
C       is not satisfied.
C
C       b) The approximate solution of (2) uses the subroutine quacan,
C       which is a bound constrained not necessarily positive 
c       semidefinite quadratic solver.
C       Given an initial approximation, quacan guarantees
C       to produce an approximation to the solution of (2) where the 
C       two-norm of the projected gradient of q , is as small as 
C       desired. In fact, the degree of accuracy desirable in the solution
C       of (2) is one of the main parameters of BOX, and the
C       best choice is currently under discussion. The stopping criterion
C       in (2) is
C
C       ||Projected gradient of the quadratic||_2
c             <= accuracy * ||Projected gradient of L at x^k||_2      (3)
C       
C       where accuracy < 1 represents the degree of accuracy required. 
c	At the first call of quacan at each iteration the precision used
c       is accuracy. At the subsequent calls of quacan within a box-iteration
c       we used the precision acumenor instead of accuracy. The idea
c       is that accuracy should be less than or equal to accumenor, since
c       a great precision in quacan is only justified at the first call,
c       when we have the chance to take (nearly) full-Newton steps.
c       
c       In april 1992 it was suggested by numerical
c       experiments that acc = 0.1 was a good choice. In november 1995
c       it was observed that, for badly scaled problems, values of acc
c       close to 0 are better. The reason is that Newton's method is invariant
c       to scaling and the criterion (3) makes the iteration close to
c       the Newton iteration when acc is close to 0.
c       The parameter acumenor, as different from accuracy, was introduced
c       in September 1996. We suggest accuracy = 1.e-3, acumenor=0.1.
c       However, this depends on the cost of quacan calls. If the number
c       of variables is small, calls to quacan are cheap. In this
c       case we recommend accuracy = acumenor = 1.e-8.
c       In some experiments in september  1996 the best accuracy was 0.1
c       associated to acumenor = 0.5.
C       In november 1995, we incorporated a second stopping criterion
c       for quacan. Namely, quacan stops also when the progress obtained
c       within the current iteration is less than dont*(the best progress
c       obtained by quacan iterations before the current one) during
c       kdont consecutive quacan iterations. Of course
c       this stopping criterion may be inhibited setting dont = 0. We
c       recommend, preliminary, to set dont = 0.01 and kdont = 5. Perhaps
c       kdont should also be dependent on n, to give a chance to the con-
c       vergence of the conjugate gradient method, that is within quacan.
C       In the description of the parameters of the subroutine we shall
C       have the opportunity of describing further characteristics of
C       the method.
C
C
C       REMARK!
C                For running this code in a PC, you will perhaps need
C       to set the card $large  at the beginning of the main program.
C       The aim of such a command is to expand 
C       memory.
C
C
C     Parameters:
c
C     iguess: Sometimes, due to the characteristics of your problem,
c       you can compute a guess of the solution of the quadratic 
c       subproblem that must be solved by Quacan, at each iteration 
c       of BOX. If this is the case, set iguess = 1, otherwise, set
c       iguess = 0. If you set iguess = 1 you need to write the sub-
c       routine guess, that computes your especial approximation to
c       the solution of the quadratic subproblem. See the comments on
c       the subroutine guess.
C
C     ipr : Control for printing in BOX. If ipr< 0 nothing is printed
c       in BOX. If ipr=0, only a
C       final summary is printed. If ipr > 0, information every ipr 
C       iterations is printed. 
C
C     n  : Dimension of problem
C
C     x : On entry, initial approximation to the solution of (1), provided
C       by the user. Remember that l <= x <= u. If these bounds do
c       not hold for your x, BOX projects your initial x on the box.
c         On exit, x is the final approximation
C       to the solution of (1), obtained by BOX.
C
C
C     l , u : On entry, these two double precision vectors are
C       the bounds of problem (1). That is, they are the l and the u of (1)
C       respectively.
C
C     flagra :  On exit, value of the objective function  L(x).
c
c     fx: On exit, value of f(x).
c
C     grad :  On exit, g is the gradient of L at the final point.
c
c     nonlc: number of components of h. (nonlc means ``nonlinear constraints'')
c
C     mu: input vector with nonlc components, that contributes to 
c     define the objective function.
c
c
c     ro: real*8 parameter
c            that contribute to define the objective function. 
c
c     ra: on input, double precision vector with at least nonlc positions
c         that contributes to the definition of the objective
c         function. If nonlc=0, you must dimension ra with 1 position.
c
c
c     mu, lambda: real*8 nonlc- and m- vectors (respectively)
c          that contribute to define the objective function.
c
c
c
c     res: On exit, when m is not 0, residual vector A x - b.
c
c     hres: On exit, when nonlc is not 0, nonlinear residual h(x).
c
c---------------------------------------------------------------------------
c
c             SUBROUTINES phi AND MAPRO, THAT DEFINE Phi(x),     
c
c
c              ITS GRADIENT, AND ITS HESSIAN APPROXIMATION
C
C       The user must provide a subroutine named phi for computing
C       the function value 
c
c                             Phi(x) =
c
c                
c                     =  f(x) +  mu^T h(x) + 
c
c              + (1/2) Sum_{i=1}^{nonlc} ra(i) h_i(x)^2  ,
c          
c
c       the gradient of Phi(x) and the information relative to the 
c       Hessian approximation of Phi(x).
c
C       The calling sequence of phi is
C
C     call phi (n, nonlc,  x, mu,  ra,  flagra,
c           fx, grad, hres, hess, inhess, modo )
C
C       where n is the number of variables, nonlc is the number of
c       components of h, 
c       x is the point where the  function is calculated within phi, 
c       mu, ra  are the other input parameters necessary
c       for computing Phi(x).
c       As output, phi must produce flagra (Phi(x)), fx (f(x)), 
C       grad, the gradient of the function Phi computed at x, hres 
c       (the nonlinear vector of residuals  h(x)), 
c       Finally, hess and inhess 
c       inhess are arrays that can contain the information relative
c       to the Hessian approximation. 
C       You can choose the name for the subroutine phi. For this
C       reason, phi is a parameter of BOX. In the calling
C       program, the name actually used must be declared EXTERNAL. 
C       If modo = 1, phi must compute ONLY the function 
c       values flagra and fx and the
c       vectors of nonlinear residuals hres and gres,
c       which, of course, are by-products of the computation of the 
c       function value flagra.
C       If modo = 2, phi must compute ONLY the gradient at
c       the point x and the information relative to the Hessian.
c       Now, you can take
c       advantage of the common calculations to function and gradient-
c       Hessian observing that a call to phi with modo=2 is always
c       preceeded, in BOX, by a call to phi with modo=1 at the same
c       point. So, you can prepare information inside phi in such a way
c       that calculations for modo=2 are already done, and you do not
c       need to begin from scratch. In particular, for computing the
c       gradient, you will need the nonlinear residuals hres and gres.
c       So, you can use it freely.
C       You can choose the data structure for the Hessian
c       information provided that it fits in the arrays inhess and 
c       hess. This information must be compatible with the coding of
c       user supplied subroutine mapro, commented below.
c       In previous versions of BOX it was assumed that the communication
c       of Hessian information between phi and mapro was coded through
c       COMMON statements. We think that passage through parameters is
c       less prone to errors, so we decided to introduce the new 
c       parameters hess and inhess in 1995. However, if you
c       find easier to make the communication by COMMON, you can do it
c       disregarding the existence of Hess and Inhess. However, do not
c       forget to dimension them.
c
c       Helping your memory:
c
c   The gradient of the objective function Phi(x) considered here is
c
c  \nabla f(x) +  Sum_{i=1}^{nonlc} (mu(i) + ra(i) h_i(x) \nabla h_i(x) 
c
c
c   The Hessian is
c
c  \nabla^2 f(x) + Sum_{i=1}^{nonlc} ra(i) \nabla h_i(x) \nabla h_i(x)^T +
c
c     + Sum_{i=1}^{nonlc} [mu(i) + ra(i) h_i(x)] \nabla^2 h_i(x)
C
c
C       You must also provide the subroutine mapro. As in the case
C       of phi , you can choose the name of this subroutine, which, for
C       this reason, must be declared EXTERNAL in the calling program.
C       mapro is called only from quacan. As a result, it is also
C       a parameter of quacan, and it is declared EXTERNAL in BOX 
C       subroutine. The calling sequence of mapro is
C
C               call mapro (n, nind, ind, u, v, hess, inhess )
C       
C       where n (the number of variables) and u (a double precision vector
C       of n positions) are the main inputs, and v, a double precision
c       vector of n positions is the output. v must be the product H * u,
c       where
C       H is the current Hessian approximation of the function Phi(x).
c       That is, H is the last  computed Hessian approximation of Phi(x)
c       within the subroutine phi. 
c       Therefore, mapro
C       must be coded in such a way that the structure given for this
C       matrix within phi is compatible with formulae for the product.
c       Moreover, if nind < n (both input parameters), the integer vector
c       ind, with nind positions, contains the indices where the input
c       u is different from zero. So, you can take advantage of this 
c       information to write the matrix-vector product, but if you do
c       not know how to do it, simply ignore nind and ind and write the
c       matrix vector product as if u were a dense vector. The algorithm
c       will be the same, but taking advantage of nind and ind makes it
c       faster. 
c       Many times, you will find the task of coding the information
c       relative to the Hessian very cumbersome. You can use a 
c       ``directional finite difference'' version of mapro instead of
c       products with true Hessians. The idea is that, at the current
c       point x, the product H u is the limit of 
c 
c               [Gradient(x + t u) - Gradient(x) ] / t
c
c       Using this directional derivative idea, you can code mapro 
c       passing, within hess, the current point x and the current 
c       gradient g to mapro. Then, you use, say, 
c
c       t = max ( 1.d-20, 1.d-8 ||x||_\infty ) / || d ||_\infty
c
c       provided that d \neq 0, of course.
c
c      So, in this case you evaluate the Gradient 
c      at the auxiliary point x + t u and 
c      finally, you use the quotient above to approximate H u. There
c      are some risks using this device, but you can try.
c
C--------------------------------------------------------------------------
c
c                         SUBROUTINE GUESS
C
C     At each iteration of BOX, bound-constrained quadratic problems of
c     the form
c
c          Minimize grad(x^k) d + (1/2) d^T B_k d
c          subject to lint <= d <= uint
c
c     are solved by the subroutine Quacan. Here, B_k is an approximation
c     of the Hessian of the objective function used in BOX (the whole
c     augmented Lagrangian). Sometimes, experienced users know how to
c     compute good approximations to the solution of this subproblem,
c     independently of Quacan. In this case, the user sets the input 
c     parameter iguess equal to 1. In fact, in that case, Quacan is going
c     to take the approximation ``computed by the user'' as initial appro-
c     ximation for its own job. When you set iguess = 1, you must code
c     your way to compute the initial approximation to the solution of
c     the bound-constrained quadratic subproblem in the subroutine guess.
c     (In fact, since the name of the subroutine is a parameter, you can
c     give other name to the subroutine, as is the case with Phi and Mapro.
c     Consequently, you must also declare external the name of this subroutine
c     in your main code.)
c     The calling sequence of guess must be:
c
c     call guess(n, x, grad, ro, ra, lambda, mu, lint, uint, d)
c
c     where you must consider that n is the number of variables, x is
c     current point in the procedure commanded by BOX, grad is the gra-
c     dient of the objective function (Augmented Lagrangian) at x, lint
c     is the vector of lower bounds for d, uint is the vector of upper
c     bounds of d, ro is the penalty parameter associated to linear 
c     constraints, ra is the vector of penalty parameters associated
c     to nonlinear equality constraints, 
c     lambda is the vector of multipliers associated to linear constraints,
c     mu is the  vector of multipliers associated to nonlinear equality 
c     constraints,
c     Finally, d (the output) is the approximate solution to 
c     the bound-constrained quadratic subproblem computed by guess.
c     All real parameters in guess must be double precision. Probably,
c     for computing your approximation you could need additional information
c     on the current point. In this case, use common statements to make
c     the communication between Phi and Guess. Probably, all the relevant
c     information necessary for Guess has already been computed in Phi,
c     with modo=2. 
c     Even if you are setting iguess=0, you must include a subroutine
c     called guess in your main stack but, in this case, it will not be
c     called by BOX, so, it can consist only of the statements return
c     and end in order of not to disturb the compilation. It is enough,
c     in the case ``iguess=0'', that you include the statements
c                             subroutine guess
c                             return
c                             end
c
c
c-------------------------------------------------------------------------
c
c         PARAMETERS THAT DEFINE THE LINEAR AUGMENTED LAGRANGIAN TERM
C
c                            
C                lambda^T (A x - b) + (ro/2) || A x - b ||^2 
c
c
c
c     m, lambda, ro, ispar, nelem, inda, a, b are the input
c        parameters that define the augmented Lagrangian term.
c
c      m : number of rows of the matrix A. Set m=0 if there is no 
c          Lagrangian term at all
c
c
c      lambda : vector of m double precision positions given in the defini-
c          tion of the objective function L.
c
c 
c      ro : real*8 number given in the definition of L
c
c      ispar : input integer parameter that can take the value 0 or 1
c              If ispar = 0, this means that the m x n matrix A is stored
c              in the array a columnwise, that is a(1,1), a(2,1), a(3,1),
c              ... a(m,1), a(1,2), a(2,2),...,a(m,2)...
c              You can use ispar=0 when there is not advantage on taking
c              into account sparsity of A. In other words, when you judge
c              that A is dense
c              If ispar=1, this means that you give only the nonzero elements
c              of A, in the way explained below.
c
c      nelem : this input parameter is used only when ispar = 1. It
c              is the number of ``nonzero'' elements that you are reporting
c              for the matrix A.
c
c      inda : this input parameter is used only when ispar = 1. In
c             this case, it is an integer nelem x 2 array where you
c             must store, in any order, the pairs (i , j) such that the
c             corresponding element a_{ij} of the matrix A is different
c             from zero. 
c
c      a    :  If ispar=0, this array contains the entries of the matrix
c              A, stored columnwise (see ispar above). If ispar =1, this
c              array contains the nonzero elements of A in such a way
c              that a(k) = a_{ij} when the row k of inda is (i, j).
c
c      b    :  real*8 vector of m positions, mentioned in the definition
c              of L(x) above.
c
C-------------------------------------------------------------------------
C
C     accuracy : accuracy demanded for quacan at its first call
c       within a box-iteration. The user must give this parameter belonging
C       to (0,1). We recommend to set Accuracy = 0.001. If the
c       objective function f is quadratic we recommend accuracy=1.d-8
c       so that most the work will be executed by quacan. A small 
c       accuracy is also desirable if the problem is badly scaled.
c	Moreover, if the number of variables is small we prefer accuracy
c       very small since in this case the quadratic solver is not very
c       costly.
c
C     acumenor : accuracy demanded for quacan at subsequent calls
c       (not the first) 
c       within a box-iteration. The user must give this parameter belonging
C       to (0,1). We recommend to set acumenor=0.1. 
c	If the number of variables is small we prefer acumenor
c       very small since in this case the quadratic solver is not very
c       costly.
c
c     relarm, absarm: two input parameters that define when the trial
c       point is accepted. Namely, if Pred < 0 is the value of the approxi-
c       mating quadratic at its approximate minimizer and x+ is the corres-
c       ponding trial point, x+ is accepted as new point when
c
c              L(x+) \leq  L(x) +  max ( relarm * Pred,  -absarm)
c
c       We recommend relarm = 0.1, absarm = 1.d-6
c
c        
C     eps : Input parameter given by the user for deciding convergence. 
c       Convergence is declared if the euclidean norm of the 
c       ``continuous projected gradient'' is less than or equal to eps.
c       The continuous projected gradient at x is defined as the
c       difference between the projection on the box of x - grad(x) and
c       x       ( Proj [ x - grad(x)] - x )
c
C     epsd : Input parameter given by the user which gives tolerance for trust
C       region radius. See usage in the description of (istop = 4) below.
C       When the method is unable to produce a decrease even with a trust
C       region of size epsd, this possibly  means that we are very close  
C       to a solution, which was not detected by the convergence criterion
C       based on the projected gradient because, perhaps, epsg was given
C       excessively small. Roughly speaking, BOX  returns because of the
C       (istop = 4) criterion, when the quadratic model restricted
C       to a ball of radius epsd is unable to produce a decrease of the
C       function. This is typical when a local minimizer occurs, but we
C       must be careful. We recommend to set epsd = 1.d-8. However, warning!
c       this is a dimensional parameter, you must take into account
c       the scaling (unit measures) of your problem. Roughly speaking,
c       epsd shoud be a NEGLIGIBLE DISTANCE in the x-space.
C
C     ftol : Input parameter given by the user which gives tolerance for
C       objective function L. 
c       See usage in the description of (istop = 1) below.
C
C
C     nafmax : Maximum allowed number of function evaluations. See 
C       description of (istop = 2) below.
C
C     itmax : Maximum allowed number of iterations. See description of
C       (istop = 3) below.
C
c
C     kont : Number of iterations performed by BOX.
C
C     naf : Number of function evaluations performed in BOX.
c
c     iquatot: Total number of iterations performed by the subroutine
c              quacan
c     
c     mvptot: Total number of matrix-vector products done within the 
c             subroutine quacan
c
C     par : This parameter is used to define the size of the new trust
C       region radius and must be given by the user belonging to (1,10).
C       We recommend to set par = 4. See usage in the description of
C       deltamin below.
c
C     delta0 : This input parameter is the initial trust region radius at
C       the beginning of iteration zero. Warning! Delta0 is dimensional.
c       It should represent the radius of a ball centered on the initial
c       point where you reasonably expect to be the solution.
C
C     deltamin : This input parameter allows the subroutine to define
C       the trust region radius. In fact, at the beginning of an 
C       iteration, the trust region radius is defined by BOX to be 
c       not less than deltamin. Due to this choice, the
C       trust region radius can inherit more or less information from the 
C       previous iteration, according to the size of deltamin. deltamin can 
C       be a fraction of the diameter of the problem (1), provided that 
C       there are no artificial bounds. We recommend deltamin=delta0/100.
C
C     istop : This output parameter tells what happened in this 
C       subroutine, according to the following conventions:
C       istop = 0   ->  Convergence : 
C                       ||projected gradient||_\infty \leq eps.
C       istop = 1   ->  Convergence : 
C                       L(x) \leq ftol
C       istop = 2   ->  It is achieved the maximum allowed number of
C                       function evaluations (nafmax).
C       istop = 3   ->  It is achieved the maximum allowed number of
C                       iterations (Itmax).
C       istop = 4   ->  Strangled point, i.e. trust region radius less
C                       than epsd.
c
C       istop = 5   ->  Data error. A lower bound is greater than an
C                       upper bound.
c
c       istop = 6   ->  Some input parameter is out of its prescribed
c                       bounds
c
C       istop = 7   ->  The progress (L(x_k) - L(x_{k-1})) in the last 
C                       iteration is less than bont * (the maximum
C                       progress obtained in previous iterations)
c                       during kbont consecutive iterations.
c
C       istop = 8   ->  The order of the norm of the continuous 
c                       projected gradient did not change 
c                       during kauts consecutive
c                       iterations. Probably, we are asking for an 
c                       exagerately small norm of continuous projected
c                       gradient for declaring convergence.
c
C     bont, kbont : This parameters play the same role as dont and kdont do
c     for quacan. We also suggest to set bont = 0.01 whenever BOX is used in a
C       iteratively way (e.g. in an Augmented Lagrangian or SQP
c       context), together with kbont = 5 .
C       Otherwise, we recommend to inhibit this parameter, using 
C       bont = 0.0.
C
c    kauts : If the order of the norm of the current 
c              continuous projected gradient did not change during 
c              kauts consecutive iterations the execution
c              stops with istop = 8. Recommended: kaustky = 10. In any
c              case kauts must be greater than or equal to 1. 
c
c     You must also set the following input quacan parameters:
c
c     dont : Positive number, less than 1, used for the second convergence
c       criterion by quacan, according to the description above. See
c       also the comments of the subroutine quacan.
c
c    eta: On input, number belonging to (0, 1) .
c        If eta is close to 1, faces are fully exploited before abandoning
c        them. If eta is close to 0, abandoning faces is frequent. We
c        recommend eta=0.1.
c
c    factor: On input, real number greater than 1 (we recommend factor=5)
c           intended to improve the current trial guess through extrapo-
c           lation procedures. It is used in the subroutine Double. See
c           its comments.
c   mitqu: maximum number of iterations allowed on each call to quacan.
c   maxmv: maximum number of matrix-vector products allowed on each call
c          to quacan.
c    ipqua: printing parameter of quacan. If ipqua < 0, nothing is printed.
c                             If ipqua = 0, only a final summary is printed
c                             of each call of quacan.
c                             Otherwise, information on quacan
c                             iterations are  printed every
c                             ipqua iterations.
c
c
c     lint, uint, s, gq, gc, xn, gn, d: auxiliar double
c                    precision vector with n positions.
c     bd: auxiliar vector that must be dimensioned with n+1 positions
c       when m = 0 an with at least 2n+m real*8 positions when m > 0
c
c     ingc, infree: integer auxiliar vectors of n positions
c

	implicit double precision (a-h, o-z)
	double precision l(n), lint(n), lambda(*), mu(*)
C
	dimension x(n), u(n), grad(n), hess(*), inhess(*)
	dimension uint(n), s(n)
	dimension gq(n), gc(n), bd(*), xn(n), gn(n)
	dimension d(n), ingc(n), infree(n)
	dimension a(*), b(*), inda(nelem,2)
	dimension res(*), hres(*), ra(*)

C
	external phi, mapro

c       open (unit = 10,file = 'box.sai')

c    We set the quacan parameter ichan equal to 1. In this way, at each
c    quacan call, quacan will test if the initial approximation given
c    is better than the null initial approximation. If it is not, the
c    initial approximation (increment) given to quacan will be automatically
c    replaced by the null vector.
	ichan = 1
c    nrepl is a counter of the number of times that the quadratic model
c    was replaced by the easy-quadratic model due to insufficient decrease of
c    the quadratic model.
c    The easy-quadratic model of the function is defined here as 
c    qeasy(d) = g^T d + ||d||^2 / 2, therefore, its solution is the 
c    projection of -g on the trust-region box
c
	reg = 0
	nkauts = 0
	nrepl = 0
	if(ipr.ge.0)then
	write(10,*)
	write(10,*)'                         OUTPUT OF BOX'
	write(10,*)
	n10=amin0(n,10)
	endif
c
c    Check whether input parameters are correct
c
	if(n.le.0.or.accuracy.lt.0.d0.or.acumenor.lt.0.d0
     *  .or.eps.lt.0.d0.or.epsd.lt.0.d0.
     *  or.nafmax.lt.0.or.itmax.lt.0.or.par.lt.1.d0.or.delta0.le.0.d0.
     *  or.deltamin.lt.0.d0.or.bont.lt.0.d0.or.kbont.le.0.or.dont.lt.
     *  0.d0.or.kdont.le.0.or.eta.le.0.d0.or.eta.gt.1.d0.or.factor.lt.
     *  1.d0.or.mitqu.lt.0.or.maxmv.lt.0.or.
     *  (m.gt.0.and.ispar.lt.0).or.(m.gt.0.and.ispar.gt.1)
     *  .or.(m.gt.0.and.(ispar.eq.1.and.nelem.le.0)).or.m.lt.0.or.
     *   nonlc.lt.0.or.kauts.lt.1)
     *  then
	ier=6
	if(ipr.ge.0)then
	write(*,*)' Some input parameter of BOX is incorrectly posed'
	write(10,*)' Some input parameter of BOX is incorrectly posed'
	endif
	return
	endif
c
	do 1 i=1,n
	   if(l(i).lt.u(i)) goto1
	   istop=6
	   if(ipr.ge.0)then
	   write(10,*)' Lower bound',i,' not smaller than'
	   write(10,*)' upper bound', i
	   endif
	   return
1       continue
c
c     Project the initial point on the feasible box, if necessary
	do 2 i=1,n
	   if(x(i).lt.l(i)) x(i)=l(i)
	   if(x(i).gt.u(i)) x(i)=u(i)
2       continue
c
c    If lambda = 0, ila is set to 0. If not, ila is set to 1.
	ila=0
	if(m.gt.0)then
	do 17 i=1,m
	if(lambda(i).eq.0.d0)goto17
	ila=1
	goto18
17      continue
	endif
C
18      kont=0
	mvptot=0
	irep = 0
	iquatot=0
	nopro=0
	progress = 0.d0

C     Calculates value of objective function, the gradient, and 
c     the Hessian information at initial point
C
        call phi (n, nonlc, x, mu, ra, flagra,
     *           fx, grad, hres, hess, inhess, 1 )
	
	if(m.gt.0) call pena(n, x, flagra, grad, res, 
     *   m, ila, lambda, ro, ispar, nelem, inda, a, b, bd, 1)
	naf = 1 
C
c     Here begins the loop
c
C
C     Test convergence 
C

3        call phi (n, nonlc, x, mu, ra, flagra,
     *           fx, grad, hres, hess, inhess, 2 )


	if(m.gt.0) call pena(n, x, flagra, grad, res, 
     *   m, ila, lambda, ro, ispar, nelem, inda, a, b, bd, 2)
	
	

	If (flagra .le. ftol) then
	   istop = 1
	   if(ipr.ge.0)then
	   write(*,*)
	   write(10,*)
	   write(*,*) ' Convergence of BOX by small function value'
	   write(10,*)' Convergence of BOX by small function value'
	   write(10,*)' Warning: Do Not consider the values printed'
	   write(10,*)' below for the norms of projected gradients'
	   write(*,*)' Warning: Do Not consider the values printed'
	   write(*,*)' below for the norms of projected gradients'
	   call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *     naf,iquatot,mvptot,delta,  pred, ared, nrepl, irep)
	   endif
	   return
	endif
c
c     Compute the 2-norm  and the sup-norm of the projected gradient
	gpnor2=0.d0
	gpcont=0.d0
	do 4 i=1,n
	if((x(i).gt.l(i).and.x(i).lt.u(i)) .or.
     *     (x(i).eq.l(i).and.grad(i).lt.0.d0) .or.
     *     (x(i).eq.u(i).and.grad(i).gt.0.d0)) then
	z=x(i)-grad(i)
	if(z.gt.u(i)) z=u(i)
	if(z.lt.l(i)) z=l(i)
	gpnor2 = gpnor2 + grad(i)**2
	gpcont = gpcont + (z-x(i))**2
	endif
4       continue
	gpnor=dsqrt(gpnor2)
	gpcont = dsqrt(gpcont)
c
c      Test whether the continuous projected gradient is small enough
c      to declare convergence
c
	if(gpcont.le.eps) then
	istop=0
	   if(ipr.ge.0)then
	   write(*,*)
	   write(10,*)
	   write(*,*) ' Convergence of BOX by small projected gradient'
	   write(10,*)' Convergence of BOX by small projected gradient'
	   call printibox(kont, n10, x, grad, flagra, gpnor, gpcont,
     *     naf, iquatot, mvptot, delta, pred, ared, nrepl, irep)
	   endif
	   return
	endif
c
c     Test whether the number of iterations is exhausted
c
	if(kont.ge.itmax) then
	istop=3
	   if(ipr.ge.0)then
	   write(*,*)
	   write(10,*)
	   write(*,*) ' Maximum number of BOX iterations exhausted'
	   write(10,*)' Maximum number of BOX iterations exhausted'
	   call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *     naf,iquatot,mvptot,delta, pred, ared, nrepl, irep)
	   endif
	   return
	endif
c
c     Test whether the number of functional evaluations is exhausted
c
	if(naf.ge.nafmax) then
	istop=2
	   if(ipr.ge.0)then
	   write(*,*)
	   write(10,*)
	   write(*,*) naf,' evaluations performed, exceeding maximum'
	   write(10,*)naf,' evaluations performed, exceeding maximum'
	   call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *     naf,iquatot,mvptot,delta, pred, ared, nrepl, irep)
	   endif
	   return
	endif
c
c       Test whether we performed many iterations without good progress
c
	if(kont.ne.0) then
	   prog=fant-flagra
	   progress=dmax1(prog,progress)
	   if(prog.le.bont*progress)then
	   nopro=nopro+1
		if(nopro.ge.kbont) then
		istop=7
		if(ipr.ge.0)then
		write(*,*)
		write(10,*)
		write(*,*) ' BOX finished by lack of progress'
		write(10,*) ' BOX finished by lack of progress'
		call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *             naf,iquatot,mvptot,delta, pred, ared, nrepl, irep)
		endif
		return
		endif
	   else
	   nopro=0
	   endif
	endif
	fant=flagra
c
c    Test whether we have performed kauts iterations without good reduction
c    of the 2-norm of the projected gradient
c
	if(kont.ne.0)then
           logp = dlog10(gpcont)
	   
	   if(logp.ge.logpant) then
	   nkauts = nkauts + 1
	   else
	   nkauts = 0
	   endif
	      if(nkauts.ge.kauts) then
	      istop = 8
		if(ipr.ge.0)then
		write(*,*)
		write(10,*)
		write(*,*) ' BOX finished by no enough improvement'
		write(*,*) ' of the continuous projected gradient'
		write(10,*) ' BOX finished by no enough improvement'
		write(10,*) ' of the continuous projected gradient'
		call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *             naf,iquatot,mvptot,delta, pred, ared, nrepl, irep)
		endif
              return
	      endif
            logpant = logp
	    else
	    logpant = dlog10(gpcont)
	    endif
c
c    A new iteration begins here
	if(ipr.gt.0.and.(kont.eq.0.or.mod(kont,ipr).eq.0))then
	call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *    naf,iquatot,mvptot,delta, pred, ared, nrepl, irep)
	endif

c    Set the convergence criterion for quacan at the first call within
c    the current iteration
	epsq=accuracy*gpnor


c    Update delta
	if(kont.eq.0)then
	delta=delta0
	else
c
c    If the actual reduction of the merit function  was 
c    greater than half the predicted reduction we multiply
c    the trust region radius by the expansion parameter par
c
	if(ared.ge.0.5d0*pred) delta = par * delta
	delta=dmin1(1.d30, dmax1(delta, deltamin))
	endif


c    Compute the bounds for quacan, lint and uint
	line=0

	do 14 i=1,n
	lint(i)= dmax1(-delta, l(i)-x(i))
14      uint(i)= dmin1(delta, u(i)-x(i))

12      if(line.eq.1)then
c
c    There was at least one Armijo failure at this iteration
c    (line=1). We update the bounds for quacan
c    and  we use as
c    initial point for quacan a fraction of the previous solution
c
	do 15 i=1,n
	lint(i)=dmax1(-delta, lint(i))
15      uint(i)=dmin1(delta, uint(i))
c
c
	do 13 i=1,n
13      s(i)=s(i)*delta/snor0

c    Set the convergence criterion for quacan at not-the-first calls within
c    the current iteration
	epsq=acumenor*gpnor


	else

c
c     The initial point for quacan at its first call within a particular
c     iteration is the null increment. However, if iguess=1 we call 
c     the user-provided subroutine guess to compute the inital approxima-
c     tion to the solution of the bound-constrained quadratic subproblem.
c
	if(iguess.eq.1) then
	call guess(n, x, grad, ro, ra, lambda, mu, lint, uint, s)
	do 26 i=1,n
	if(s(i).lt.lint(i)) s(i) = lint(i)
	if(s(i).gt.uint(i)) s(i) = uint(i)
26	continue
	else
	do 19 i=1,n
19      s(i)=0.d0
	endif

	endif


c
c    Solve, approximately, the quadratic subproblem
c

	call quacan (mapro, grad, n, s, fq, gq, lint, uint, eta, factor,
     *    kon, mvp, ipqua, mitqu, maxmv, dont, kdont, epsq, ier, 
     *    gc, bd, xn, gn, d, ingc, infree, hess, inhess,
     *    m, ro, reg, ispar, nelem, inda, a, ichan, irep0)
	
c
	iquatot=iquatot+kon
	mvptot=mvptot+mvp
	irep = irep + irep0
c
c    Now we test whether the quadratic model produced enough decrease,
c    that is, we test whether fq is small enough.
c    For this purpose, we consider the ``easy-quadratic model'', and we 
c    compute d, the minimizer of the easy-quadratic model in the trust region
c    box. If the quadratic model did not produce a decrease at least
c    equal to some fraction of the decrease produced by the easy-quadratic
c    model, the solution of the quadratic model is replaced by the
c    one of the easy-quadratic model
c
	flimo = 0.d0
	dtd = 0.d0
	do 24 i = 1, n
	d(i)=-grad(i)
	if(d(i).lt.lint(i)) d(i) = lint(i)
	if(d(i).gt.uint(i)) d(i) = uint(i)
	dtd = dtd + d(i)**2
24	flimo = flimo + d(i) * grad(i)
	flimo = flimo + dtd/2.d0
	if(fq .gt. 1.d-6 * flimo) then
	nrepl = nrepl + 1
	do 25 i=1,n
25	s(i)=d(i)
	fq = flimo
	endif

c
c    The vector s contains our trial increment. Now we test whether it
c    can be accepted.
c    xn will contain the trial point
c
	do 9 i=1,n
	xn(i)=x(i)+s(i)
c
c   These are safeguards to ensure that the trial point do not
c   escape from the box by rounding errors, which should be 
c   catastrophic. 
c   The quantity 1.d-14 is meant to be something a litter bit larger
c   than the machine precision. You must change it if the machine
c   precision changes. Here it is assumed to be 1.d-16
c
	if(xn(i).gt.u(i) - 1.d-14 * dabs(u(i)))xn(i)=u(i)
	if(xn(i).lt.l(i) + 1.d-14 * dabs(l(i)))xn(i)=l(i)
9       continue
c
c    Compute the functional value at the trial point
	call phi (n, nonlc,  xn, mu,  ra, fn, fxn, gn, hres, 
     *   hess, inhess, 1)
	if(m.gt.0) call pena (n, xn, fn, gn, res, 
     *   m, ila, lambda, ro, ispar, nelem, inda, a, b, bd, 1)
	naf = naf + 1
	if(ipr.eq.1)then
	write(10, *)' Trust region radius:', delta
	write(*, *)' Trust region radius:', delta
	write(10,*)' Predicted reduction:', -fq
	write(10,*)' Actual reduction:', flagra - fn
	write(*,*)' Predicted reduction:', -fq
	write(10,*)' Reason for termination of quacan, ier =',ier
	write(*,*)' Reason for termination of quacan, ier =',ier
	write(10,*)' Number of iterations at last call to quacan:',kon
	write(*,*)' Number of iterations at last call to quacan:',kon
	write(*,*)' Actual reduction:', flagra - fn
	write(10,*)' Objective function value at trial point:',fn
	write(*,*)' Objective function value at trial point:',fn
	endif
c
c    Test if the trial point can be accepted
c
	desce = dmax1 (relarm * fq, - absarm)
	if ( fn. le . flagra + desce ) then
c
c    The trial point is accepted and is going to be the new iterate
c
	do 10 i=1,n
10      x(i)=xn(i)
	pred = -fq
	ared = flagra - fn
	flagra=fn
	fx=fxn
	kont=kont+1
	goto3
c
	endif
c
c   The trial point was not good enough. Reduce delta
c
c
c   First, verify if delta is very small (strangled point)
c
	if(delta.le.epsd)then
	istop=4
	if(ipr.ge.0)then
	write(*,*)
	write(10,*)
	write(*,*)' BOX stops by excessively small trust region'
	write(*,*)' (strangled point)'  
	write(10,*)' BOX stops by excessively small trust region'
	write(10,*)' (strangled point)' 
	call printibox(kont,n10,x,grad,flagra,gpnor,gpcont,
     *       naf,iquatot,mvptot,delta, pred, ared, nrepl, irep)
	endif
	return
	endif

c    Updating delta after a failure of the sufficient descent 
c    condition
c
	snor0=0.d0
	do 11 i=1,n
11      snor0= dmax1(snor0, dabs(s(i)))
c
c    contrac is a contraction factor for the trust region radius.
c    If fn was less than flagra - 0.1 fq
c    contrac is set to be equal to 2. (Therefore, the trust-region 
c    radius is not excessively reduced.)
c    If fn was greater than flagra - 0.1 fq we set contrac equal to 10.
c    That is, is fn was much larger than flagra we reduce the trust-region
c    radius rather drastically. 
c
	if(fn.le.flagra - 0.1d0 * fq) then
	contrac = 2.d0
	else
	contrac = 10.d0
	endif

	delta = snor0 / contrac
	line=1
	goto12
c
	end


	subroutine printibox(kon,n10,x,grad,f,gpnor,gpcont,
     *   naf,iquatot,mvp,del, pred, ared, nrepl, irep)
	implicit double precision(a-h,o-z)
	dimension x(n10), grad(n10)
	write(10,*)
	write(10,*)' BOX iteration ', kon
	write(10,*)' First (at most 10) components of current point:'
	write(10,*)(x(i), i=1,n10)
	write(10,*)' First (at most 10) components of the gradient:'
	write(10,*)(grad(i), i=1,n10)
	write(10,*)' Objective function value:',f




	write(*,*)
	write(*,*)' BOX iteration ', kon
	write(*,*)' First (at most 10) components of current point:'
	write(*,*)(x(i), i=1,n10)
	write(*,*)' First (at most 10) components of the gradient:'
	write(*,*)(grad(i), i=1,n10)
	write(*,*)' Objective function value:',f



	if(kon.gt.0) then
	write(10,*)' Predicted reduction:', pred
	write(10,*)' Actual reduction:', ared

	write(*,*)' Predicted reduction:', pred
	write(*,*)' Actual reduction:', ared

	endif

	write(10,*)' 2-Norm of the continuous projected gradient :',
     *               gpcont
	write(10,*)' 2-Norm of the (non-continuous) projected gradient:'
     *             , gpnor
	write(10,*)' Functional evaluations:', naf
	write(10,*)' Total number of quacan iterations:', iquatot
	write(10,*)' Number of matrix-vector products:', mvp
	write(10,*)' Number of times in which the solution of the'
	write(10,*)' quadratic model was replaced by the solution of'
	write(10,*)' the easy-quadratic model:', nrepl
	write(10,*)' Number of times in which the guessed increment'
	write(10,*)' or, perhaps, the backtracked increment'
	write(10,*)' was worse than the null increment in terms of the'
	write(10,*)' quadratic model:', irep


	write(*,*)' 2-Norm of the continuous projected gradient :',
     *               gpcont
	write(*,*)' 2-Norm of the (non-continuous) projected gradient:'
     *             , gpnor
	write(*,*)' Functional evaluations:', naf
	write(*,*)' Total number of quacan iterations:', iquatot
	write(*,*)' Number of matrix-vector products:', mvp
	write(*,*)' Number of times in which the solution of the'
	write(*,*)' quadratic model was replaced by the solution of'
	write(*,*)' the easy-quadratic model:', nrepl
	write(*,*)' Number of times in which the guessed increment'
	write(*,*)' or, perhaps, the backtracked increment'
	write(*,*)' was worse than the null increment in terms of the'
	write(*,*)' quadratic model:', irep

	if(kon.ne.0)then
	write(10,*)' The current point was obtained within a trust'
	write(10,*)' region of radius', del

	write(*,*)' The current point was obtained within a trust'
	write(*,*)' region of radius', del


	endif
	write(10,*)
	write(*,*)

	return
	end
	



C
C----------------------------------------------------------------------
	subroutine quacan (mapro, b, n, x, f, g, l, u, eta, factor,
     *    kon, mvp, ipri, maxit, maxef, dont, kdont, eps, ier, 
     *    gc, bd, xn, gn, d, ingc, infree, hess, inhess,
     *    mrowsa, ro, reg, ispar, nelem, inda, amat, ichan, irep0)


c    
c    Initiated in November 1995 
c
c    This subroutine aims to minimize a quadratic function
c
c        f(x) = (1/2) x^T ( B + ro A^T A + reg I ) x + b^T x 
c 
c    (f:\R^n \to \R) on the box given by l \leq x \leq u. 
c    It is especially suited for n large. 
c    The matrix A has mrowsa rows and n columns and can be stored dense
c    or sparse according to the parameter ispar. 
c    Quacan replaces a previous version, avoiding
c    the cumbersome driving of indices that characterizes active set
c    strategies. 
c    The main purpose was to develop an ``easy code'', easy to manipu-
c    late and modify for testing different ideas.
c    The method implemented in Quacan is described in the report BFGMR
c    (paper by Bielschowky, Friedlander, Gomes, Martinez and Raydan).
c    It is based on a mild active set strategy that uses conjugate 
c    gradients inside the faces, projected searches and chopped
c    gradients to leave the faces. The criterion to leave a face is
c    
c                       ||g_c|| \geq eta  ||g_p||                 (1)
c
c   where g_c is the chopped gradient, g_p is the projected gradient,
c   defined as in BFGMR and || . || is the euclidian norm.
c
c   Parameters:
c   Mapro: subroutine that must be declared external in the calling 
c   routine or program. The calling sequence of mapro is
c                   call mapro(n, nind, ind, u, v)
c     This subroutine must be coded by the user, taking into account that
c     n is the number of variables of the problem and that v must be 
c     the product B u. Moreover, you must assume, when you code mapro,
c     that only nind components of u are nonnull and that ind is the set
c     of indices of those components. In other words, you must write
c     mapro in such a way that v is the vector whose i-th  entry  is 
c                     \Sum_{j=1}^{nind} B_{i ind(j)} u_ind(j)
c     However, observe that you must assume that, in u, the whole vector
c     is present, with its n components, even the zeroes. So, if you
c     decide to code mapro without taking into account the presence 
c     of ind and nind, you can do it. A final advertence concerning
c     your coding of mapro. You must test, in the code, if nind = n.
c     In this case, do not use ind, because it is a void vector and,
c     of course, has no utility. In other words, if nind=n you must 
c     not assume that ind is the vector (1, 2, ..., n). It is not. A
c     final observation: probably, if nind is close to n, it is not
c     worthwhile to use ind, due to the cost of accessing the correct
c     indices. If you want, you can test, within your mapro, if 
c     (say) nind > n/2, and, in this case use a straightforward scalar
c     product for the components of v.
c
c----------------------------------------------------------------------
c         INPUT PARAMETERS THAT DEFINE RO AND THE MATRIX A
c
c               mrowsa, ro, ispar, nelem, inda, amat
c
c
c      mrowsa : number of rows of the matrix A. Set mrowsa = 0 if there is no 
c          Lagrangian term at all
c
c      ro : real*8 number given in the definition of the problem
c
c      ispar : input integer parameter that can take the value 0 or 1
c              If ispar = 0, this means that the m x n matrix A is stored
c              in the array a columnwise, that is a(1,1), a(2,1), a(3,1),
c              ... a(m,1), a(1,2), a(2,2),...,a(m,2)...
c              You can use ispar=0 when there is not advantage on taking
c              into account sparsity of A. In other words, when you judge
c              that A is dense
c              If ispar=1, this means that you give only the nonzero elements
c              of A, in the way explained below.
c
c      nelem : this input parameter is used only when ispar = 1. It
c              is the number of ``nonzero'' elements that you are reporting
c              for the matrix A. Set nelem = 1 if ispar is not 1.
c
c      inda : this input parameter is used only when ispar = 1. In
c             this case, it is an integer nelem x 2 array where you
c             must store, in any order, the pairs (i , j) such that the
c             corresponding element a_{ij} of the matrix A is different
c             from zero. 
c
c      amat :  If ispar=0, this array contains the entries of the matrix
c              A, stored columnwise (see ispar above). If ispar =1, this
c              array contains the nonzero elements of A in such a way
c              that a(k) = a_{ij} when the row k de inda is (i, j).
c
c
c      ichan : Input integer parameter. If you set ichan = 1, quacan
c              tests if the initial approximation is better than the
c              null initial approximation. If it is not, quacan changes
c              the given initial approximation by the vector 0. In 
c              other words, if the quadratic value at the given initial
c              approximation is greater than 0, the initial approxima-
c              tion is replaced by the null vector. If you set ichan 
c              different from 1, the initial approximation given is
c              not changed, no matter its functional value.
c
c      irep0:  Output parameter that can take the values 0 or 1. If 
c              irep0 = 1, this means that, being ichan=1, the initial
c              point of quacan was really changed to the null initial
c              point.
c    
c-------------------------------------------------------------------------
c             PARAMETER RELATED TO THE REGULARIZATION TERM
C
C   reg: real*8 regularization parameter.
c
c
c-------------------------------------------------------------------------
c
c   n: number of variables.
c   x (dimension n): on entry, initial approximation, feasible 
c     to the box, on exit, best point obtained.
c   f: on exit, value of f(x).
c   g: when convergence ocurs, this vector (dimension n) contains the
c      final values of the gradient at x.
c   eta: On input, number belonging to (0, 1) according to (1) above.
c        If eta is close to 1, faces are fully exploited before abandoning
c        them. If eta is close to 0, abandoning faces is frequent.
c   factor: On input, real number greater than 1 (we recommend factor=5)
c           intended to improve the current trial guess through extrapo-
c           lation procedures. It is used in the subroutine Double. See
c           its comments.
c   eps: Small positive number for declaring convergence when  the eucli-
c        dian norm of the projected gradient is less than
c        or equal to eps.
c   maxit: maximum number of iterations allowed.
c   maxef: maximum number of matrix-vector products allowed.
c   kon: on exit, number of iterations performed.
c   mvp: on exit, matrix-vector products (calls to mapro)
c   dont: ``lack of enough progress'' measure. The algorithm stops by
c        ``lack of enough progress'' when 
c          f(x_k) - f(x_{k+1}) \leq  dont * max \{f(x_j)-f(x_{j+1}, j<k\}
c          during kdont consecutive iterations.
c   kdont: see the meaning of dont, above.
c   ier: output message.
c        If ier=0, convergence was declared.
c        If ier=1, the maximum number of iterations was exhausted.
c        If ier=2, the maximum number of matrix-vector products was exhausted.
c        If ier=3, the method stopped by ``lack of enough progress''.
c        If ier=4, the initial point was not within the box.
c        If ier=5, there are input parameters that are not within their
c                  limits. Check eps, eta, etc.
c        If ier=6, some component of u is less than or equal to the 
c                  corresponding component of l.
c   ipri: printing parameter. If ipri < 0, nothing is printed.
c                             If ipri = 0, only a final summary is printed
c                             Otherwise, information is printed every
c                             ipri iterations.
c   gc, xn, gn, d : auxiliar double precision real vectors of n positions.
c   bd: auxiliar double precision real vector of n+1 positions. (Warning:
c   I think that the previous comment is wrong. See dimensioning of bd
c   in BOX). 
c   ingc, infree : auxiliar integer vectors of n positions.
c
c   hess, inhess : double precision and integer array, respectively,
c   that must be dimensioned in the main problem with the number of
c   positions sufficient to pass to mapro the necessary information
c   to perform matrix-vector products, essentially when quacan is
c   used as a subroutine of BOX. If quacan is used independently, as
c   in the example below, you can ignore them. 
c

 

	implicit double precision (a-h, o-z)
	external mapro
	dimension amat(*), inda(nelem,2)
	double precision l(n)
	dimension x(n), g(n), u(n), b(n)
	dimension gc(n), bd(*), xn(n), d(n), gn(n)
	dimension ingc(n), infree(n)
	dimension hess(*), inhess(*)
c
	irep0 = 0
	if(ipri.ge.0)then
	write(10,*)
	write(*,*)
	write(*,*)'                          OUTPUT OF QUACAN:'
	write(*,*)
	write(10,*)'                         OUTPUT OF QUACAN:'
	write(10,*)
	endif
c
c   Test if all the input parameters are within their limits
c
	if(eps.lt.0.d0.or.eta.le.0.d0.or.eta.gt.1.d0.or.dont.lt.0.d0
     *    .or.n.le.0.or.maxit.lt.0.or.maxef.lt.0.or.kdont.le.0
     *    .or.factor.lt.1.d0)then
	ier=5
	    if(ipri.ge.0)then
	    write(*,*)' Input parameters out of their prescribed bounds'
	    write(10,*)' Input parameters out of prescribed bounds'
	    endif
	return
	endif
c   Check if l < u
c
	do 8 i=1,n
	if(u(i).le.l(i))then
	ier=6
	if(ipri.ge.0)then
	write(*,*)' Component',i,' of l is >= than component',i,' of u'
	write(10,*)' Component',i,' of l is >= than component',i,' of u'
	endif
	return
	endif
8       continue
c
c   Test if the initial point is within to the box
	do 1 i = 1, n
	if(x(i).lt.l(i).or.x(i).gt.u(i))then
	ier=4
	if(ipri.lt.0) return
	write(*,*)
	write(*,*)' The initial point is not feasible'
	write(*,*)
	write(10,*)
	write(10,*)' The initial point is not feasible'
	write(10,*)
	return
	endif
1       continue
c
	indica=0
c  indica=1 means that the iteration that begins now is of conjugate
c  gradient type. indica=0 means that it is of chopped gradient type
c  or internal gradient type.
	kon=0
	mvp=0
	if(ipri.ge.0) n10=min0(n,10)
	noprog=0
c
c   Progress is the maximum progress obtained up to now
	progress=0.d0
c
c       Evaluate the gradient at the initial point
	call grad (n, mapro, b, x, g, mvp, hess, inhess,
     *   mrowsa, ro, reg, ispar, nelem, inda, amat, 
     *   bd(n+1), bd(n+mrowsa+1))       
c       Evaluate the objective function at the initial point
	call fuqu(n, x, g, b, f)
c
	if(ichan.eq.1) then 
c   Test if the initial point given is better than the null vector
c   If it is not, it will be changed.
	if(f. gt. 0.d0) then 
c   Replace the given initial point by the null vector 
	irep0 = 1
        do 23  i = 1, n  
23      x(i) = 0.d0
c
c       Evaluate the gradient at the initial point
	call grad (n, mapro, b, x, g, mvp, hess, inhess,
     *   mrowsa, ro, reg, ispar, nelem, inda, amat, 
     *   bd(n+1), bd(n+mrowsa+1))       
c       Evaluate the objective function at the initial point
	call fuqu(n, x, g, b, f)
c
	endif
	endif
c
c       Here begins the iteration loop
c
c       nfree is the number of components of the internal gradient
c       (number of free variables)
c       infree is the vector of indices of components of the internal
c       gradient (free variables).
c       ncgc is the number of components of the chopped gradient
c       ingc is the vector of indices of the components of the chopped
c       gradient.
c
10      nfree=0
	ncgc=0
	do 3 i=1,n
	if(x(i).gt.l(i).and.x(i).lt.u(i))then
	nfree=nfree+1
	infree(nfree)=i
	endif
	if(x(i).eq.l(i).and.g(i).lt.0.d0)then
	ncgc=ncgc+1
	ingc(ncgc)=i
	endif
	if(x(i).eq.u(i).and.g(i).gt.0.d0)then
	ncgc=ncgc+1
	ingc(ncgc)=i
	endif
3       continue
c
c
c       Compute the squared 2-norm of the internal gradient
c       However, if indica=1, this is not necessary since it has
c       been already computed at the end of the previous iteration
	if(indica.eq.0)then
	ginor2=0.d0
	    if(nfree.gt.0)then
	    do 4 i=1,nfree
	    j=infree(i)
4           ginor2=ginor2+g(j)**2
	    endif
	endif
c       Compute the 2-norm of the chopped gradient
	gcnor2=0.d0
	if(ncgc.gt.0)then
	do 22 i=1,ncgc
	j=ingc(i)
22      gcnor2=gcnor2+g(j)**2
	endif
c       Compute the 2-norm of the projected gradient
	gcnor=dsqrt(gcnor2)
	gpnor2=ginor2+gcnor2
	gpnor=dsqrt(gpnor2)
c
c       Test convergence criterion
c
	if(gpnor.le.eps)then
	ier=0
	if(ipri.ge.0)then
	write(*,*)
	write(10,*)
	write(*,*)' Convergence detected at iteration ', kon
	write(10,*)' Convergence detected at iteration ', kon
	call printi(kon,n,n10,x,g,f,gpnor,gcnor,nfree,ncgc,mvp,ichop,
     *  internal, iconju)
	write(10,*)' Use Quacan and you will be happy for ever!!'
	write(*,*)' Use Quacan and you will be happy for ever!!'
c
	write(*,*)
	write(10,*)
	endif
	return
	endif
c
c       Test maximum number of iterations
c
	if(kon.ge.maxit)then
	ier=1
	if(ipri.ge.0)then
	write(*,*)
	write(10,*)
	write(*,*)' Maximum number of iterations ', kon,' reached'
	write(10,*)' Maximum number of iterations ', kon,' reached'
	call printi(kon,n,n10,x,g,f,gpnor,gcnor,nfree,ncgc,mvp,
     *  ichop,internal, iconju)
	endif
	return
	endif
c
c       Test maximum number of matrix-vector products
c

	if(mvp.ge.maxef)then
	ier=2
	if(ipri.ge.0)then
	write(*,*)
	write(10,*)
	write(*,*)' Maximum number of matrix-vector products ',
     *   maxef,' reached'
	write(10,*)' Maximum number of matrix-vector products ',
     *   maxef,' reached'
	call printi(kon,n,n10,x,g,f,gpnor,gcnor,nfree,ncgc,mvp,
     *  ichop,internal, iconju)

	endif
	return
	endif
	if(kon.ne.0)then
	prog=dmax1(0.d0, fant-f)
	progress=dmax1(prog, progress)
	if(prog.le.dont*progress)then
	 noprog=noprog+1
	  if(noprog.ge.kdont)then
	  ier=3
	   if(ipri.ge.0)then
	   write(*,*)
	   write(10,*)
	   write(*,*)' Quacan stops because of lack of progress'
	   write(10,*)' Quacan stops because of lack of progress'
	   call printi(kon,n,n10,x,g,f,gpnor,gcnor,nfree,ncgc,mvp,
     *     ichop,internal, iconju)
	   endif
	  return
	  endif
	else
	  noprog=0
	endif
	endif
	fant=f
c
c       Printing session
c
	if(ipri.gt.0)then
	if(mod(kon,ipri).eq.0.or.kon.eq.0)then
	call printi(kon,n,n10,x,g,f,gpnor,gcnor,nfree,ncgc,mvp,
     *  ichop,internal, iconju)

	endif
	endif   
c
c
c       A new iteration is going to be performed
	kon=kon+1
c
c       Test if the current face must be leaved or not
c
	if(gcnor.ge.eta*gpnor)then
c   ichop, internal and iconju are to indicate the printer which
c   type of iteration has been performed
	if(ipri.ge.0)then
	ichop=1
	internal=0
	iconju=0
	endif

c
c       The current face must be abandoned
c
c       Use the chopped gradient to leave it
c
c
c       gc is the (negative) chopped gradient vector
c
	do 5 i=1,n
5       gc(i)=0.d0
	do 6 i=1,ncgc
	j=ingc(i)
	gc(j)= -g(j)
6       continue
c
c       Compute the minimum breakpoint alfabreak along the chopped
c       gradient direction. (Observe that all the components of gc
c       that appear dividing are different from zero.)
c
	j=ingc(1)
	if(x(j).eq.l(j)) then
	alfabreak =  (u(j) - l(j))/gc(j)
	jbreak=j
	else
	alfabreak = (l(j) - u(j))/gc(j)
	jbreak=j
	endif
	if(ncgc.gt.1)then
	do 9 i = 2, ncgc
	j=ingc(i)
	if(x(j).eq.l(j)) then
	alfa = (u(j) - l(j))/gc(j)
	if(alfa.lt.alfabreak)then
	alfabreak=alfa
	jbreak=j
	endif
	else
	alfa = (l(j) - u(j))/gc(j)
	if(alfa.lt.alfabreak)then
	alfabreak=alfa
	jbreak=j
	endif
	endif
9       continue
	endif   
c
c
c
c       Compute the product of the Hessian times the chopped gradient

	call mapro(n, ncgc, ingc, gc, bd, hess, inhess)
	if(mrowsa.gt.0)call roata(n, ncgc, ingc, gc, bd, 
     *     mrowsa, ro, reg, ispar, nelem, inda, amat, bd(n+1), 
     *     bd(n+mrowsa+1))
	mvp=mvp+1
c
c       Compute the denominator for the linesearch
c
	den=0.d0
	do 7 i=1,ncgc
c    In the following line an overflow appeared on 28/12/95, running gedan
7       den=den + gc(ingc(i)) * bd(ingc(i))
c  
c     If den .le. 0, the next iteration will be the minimum breakpoint
c     along the chopped gradient direction, or, perhaps, something
c     better (after the double-stepping procedure)
c               
	if(den.le.0.d0) then
	call double (n, b, x, f, g, gc, ingc, ncgc, l, u, mapro, factor,
     *     alfabreak, jbreak, xn, gn, bd, mvp, hess, inhess, 
     *      mrowsa, ro, reg, ispar, nelem, inda, amat)
c     
c       The new iteration has been computed and stored in x
c       The new gradient is stored in g
c       The new objective function value is at f
c       The iteration stops here
c       The next iteration will not be conjugate
	indica=0
	goto10
	endif


c       Compute the numerator of the linesearch coefficient
c
	alfa= gcnor2/den
	if(alfa.ge.alfabreak) then              
	call double (n, b, x, f, g, gc, ingc, ncgc, l, u, mapro, factor,
     *     alfabreak, jbreak, xn, gn, bd, mvp, hess, inhess, 
     *      mrowsa, ro, reg, ispar, nelem, inda, amat)

c     
c       The new iteration has been computed and stored in x
c       The new gradient is stored in g
c       The new objective function value is at f
c       The iteration stops here
c       The next iteration will not be conjugate (indica=0)
	indica=0
	goto10
	endif
c
c    If the minimizer along the direction of the chopped gradient is
c    before the minimum breakpoint, we adopt this minimizer as new
c    iterate
c
	do 12 i=1,ncgc
	j=ingc(i)
12      x(j)=x(j)+alfa*gc(j)
c
c    Compute the gradient at the new point x
	do 13 i=1,n
13      g(i)=g(i)+alfa*bd(i)
c
c    Compute the new objective function value
	call fuqu(n, x, g, b, f)
c    The iteration stops here
c
c    The next iteration will not be conjugate (indica=0)
	indica=0
	goto10
c    Here finishes the ``if'' that begins with ``if(gcnor.ge.eta*gpnor)''
c
	else
c    Now, we consider the case where the face must not be abandoned
c    that is, gcnor < eta*gpnor
c    In this case, we perform conjugate gradient iterations
c    However, we need an indicator for telling us if the iteration
c    must be ``conjugate gradient'' or merely gradient. A conjugate
c    gradient iteration will take place only if the indicator 
c    indica is equal to 1. Otherwise, this will be a gradient iteration
c    along the (negative) internal gradient. Observe that we set indica=0 at 
c    the steps of the algorithm that corresponds to chopped gradient
c    iterations.
c    Put the search direction on vector d
	if(indica.eq.0)then
c    Gradient search direction
	do 15 i=1,n
15      d(i)=0.d0
	do 14 j=1,nfree
	i=infree(j)
14      d(i)=-g(i)
	endif
	if(indica.eq.1)then
c    Conjugate search direction
	do 19 j=1,nfree
	i=infree(j)
19      d(i)= -g(i) + beta*d(i)
	endif
c
c   Compute the minimum breakpoint along d
	alfabreak=-1.d0
	do 16 i=1,nfree
	j=infree(i)
	if(d(j).eq.0.d0)goto16
	alfa = (u(j)-x(j))/d(j)
	if(alfa.gt.0.d0)then
	if(alfabreak.eq.-1.d0.or.alfa.lt.alfabreak)then
	alfabreak=alfa
	jbreak=j
	goto16
	endif
	else
	alfa = (l(j)-x(j))/d(j)
	if(alfa.le.0.d0)goto16
	if(alfabreak.eq.-1.d0.or.alfa.lt.alfabreak)then
	alfabreak=alfa
	jbreak=j
	endif
	endif
16      continue
c
c   Compute the denominator of the linesearch
	
	call mapro(n, nfree, infree, d, bd, hess, inhess)
	if(mrowsa.gt.0)call roata(n, nfree, infree, d, bd, 
     *     mrowsa, ro, reg, ispar, nelem, inda, amat, bd(n+1), 
     *     bd(n+mrowsa+1))
	mvp=mvp+1
	den=0.d0
	do 17 i=1,nfree
	j=infree(i)
17      den=den+bd(j)*d(j)
c
c   If the denominator of the linesearch is .le. 0, go to the breakpoint
c
	if(den.le.0.d0)then
	call double (n, b, x, f, g, d, infree, nfree,
     *     l, u, mapro, factor, alfabreak, jbreak, xn, gn, bd, mvp,
     *     hess, inhess, 
     *     mrowsa, ro, reg, ispar, nelem, inda, amat )
c     
c       The new iteration has been computed and stored in x
c       The new gradient is stored in g
c       The new objective function value is at f
c       The iteration stops here
	indica=0
c   ichop, internal and iconju are to indicate the printer which
c   type of iteration has been performed
	if(ipri.ge.0)then
	ichop=0
	internal=1
	iconju=0
	endif
	goto10
	endif
c       Compute the linesearch coefficient
	alfa= ginor2/den
	if(alfa.ge.alfabreak) then      
	call double (n, b, x, f, g, d, infree, nfree, l, u, 
     *     mapro, factor, alfabreak, jbreak, xn, gn, bd, mvp,
     *     hess, inhess, mrowsa, ro, reg, ispar, nelem, inda, amat)
c     
c       The new iteration has been computed and stored in x
c       The new gradient is stored in g
c       The new objective function value is at f
c       The iteration stops here
c   ichop, internal and iconju are to indicate the printer which
c   type of iteration has been performed
	if(ipri.ge.0)then
	ichop=0
	if(indica.eq.0)then
	internal=1
	iconju=0
	else
	iconju=1
	internal=0
	endif
	endif
c    The next iteration will not be conjugate (indica=0)
	indica=0
	goto10
	else

c
c    The new iterate is in the same face. The next iteration will
c    be conjugate
	do 18 i=1,nfree
	j=infree(i)
18      x(j)=x(j)+alfa*d(j)
	do 20 i=1,n
20      g(i)=g(i)+alfa*bd(i)
	gant2=ginor2
	ginor2=0.d0
	do 21 j=1,nfree
	i=infree(j)
21      ginor2=ginor2+g(i)**2
	beta=ginor2/gant2
	call fuqu(n, x, g, b, f)
	if(ipri.ge.0)then
	ichop=0
	if(indica.eq.0)then
	internal=1
	iconju=0
	else
	iconju=1
	internal=0
	endif
	endif
	indica=1
	goto10
	endif
	endif
	end

c  End of subroutine Quacan




	subroutine grad (n, mapro, b, x, g, mvp, hess, inhess,
     *     mrowsa, ro, reg, ispar, nelem, inda, amat, u, v)     
	implicit double precision (a-h, o-z)
	dimension x(n), b(n), g(n), nada(1)
	dimension hess(*), inhess(*)
	dimension inda(nelem,2), amat(*)
c   The following line was missing until January 16, 2002
	dimension u(*), v(*)
c       This subroutine is   called by quacan to compute the gradient
c       of the quadratic f at the point x. 
c       So, the output vector g is
c                  g = (B + ro A^T A + reg I) x + b
c       The product B x is computed using the user subroutine mapro,
c       which is described in the comments of Quacan. 
c       mvp increments in 1 the number of matrix-vector products.
c
c
	call mapro (n, n, nada, x, g, hess, inhess)
c
c
c
c       Add to B x the term        ro A^T A x
c
	if(mrowsa.ne.0)then
	call roata (n, n, nada, x, g, 
     *     mrowsa, ro, reg, ispar, nelem, inda, amat, u, v)
	endif
	mvp=mvp+1
	do 1 i=1,n
1       g(i)=g(i)+b(i)
	return
	end

c   End of subroutine grad




	subroutine printi(kon,n,n10,x,g,f,gpnor,gcnor,nfree,ncgc,mvp,
     *  ichop,internal, iconju)
	implicit double precision(a-h,o-z)
	dimension x(n10), g(n10)
	write(10,*)
	write(10,*)' Quacan-iteration ', kon
	write(*,*)' Quacan-iteration ', kon
	if(kon.gt.0)then
	if(ichop.eq.1)then
	write(10,*)' This point comes from a chopped gradient search'
	write(*,*)' This point comes from a chopped gradient search'
	endif
	if(internal.eq.1)then
	write(10,*)' This point comes from an internal gradient search'
	write(*,*)' This point comes from an internal gradient search'
	endif
	if(iconju.eq.1)then
	write(10,*)' This point comes from a conj. gradient search'
	write(*,*)' This point comes from a conj. gradient search'
	endif
	endif
	write(10,*)' First (at most 10) components of current point:'
	write(10,*)(x(i), i=1,n10)
	write(10,*)' First (at most 10) components of the gradient:'
	write(10,*)(g(i), i=1,n10)
	write(10,*)' Value of the quadratic objective function:',f
	write(10,*)' 2-Norm of the projected gradient:', gpnor
	write(10,*)' 2-Norm of the chopped gradient:', gcnor
	write(10,*)' Number of free variables:', nfree
	nbound=n-nfree
	write(10,*)' Number of variables on their bounds:',nbound
	write(10,*)' Number of components of chopped gradient:',ncgc
	write(10,*)' Number of matrix-vector products:', mvp
	write(10,*)
	write(*,*)
	write(*,*)' First (at most 10) components of current point:'
	write(*,*)(x(i), i=1,n10)
	write(*,*)' Value of the quadratic objective function:',f
	write(*,*)' Norm of the projected gradient:', gpnor
	write(*,*)' Norm of the chopped gradient:', gcnor
	write(*,*)' Number of free variables:', nfree
	write(*,*)' Number of variables on their bounds:',nbound
	write(*,*)' Number of components of chopped gradient:',ncgc
	write(*,*)' Number of matrix-vector products:', mvp
	write(*,*)
	return
	end

	subroutine fuqu(n, x, g, b, f)
	implicit double precision (a-h,o-z)
	dimension x(n), g(n), b(n)
c   This subroutine evaluates 
c            f(x) = (1/2) x^T B x + b^T x
c   using    g(x) = B x + b
c
c   We use the formula
c
c  f(x) = (1/2) x^T [B x + b] + b^T x / 2 = (1/2) x^T g(x) + b^T x / 2  
c           = x^T (g(x) + b)/2
c
	f=0.d0
	do 7 i=1,n
7       f=f+ x(i) * (g(i) + b(i))
	f=f/2.d0
	return
	end





	subroutine double (n, b, x, f, g, d, infree, nfree, l, u, 
     *     mapro, factor, alfabreak, jbreak, xn, gn, bd, mvp, 
     *     hess, inhess, mrowsa, ro, reg, ispar, nelem, inda, amat)
	implicit double precision (a-h, o-z)
	double precision l(n)
	external mapro
	dimension x(n), d(n), u(n), g(n), b(n)
	dimension infree(n)
	dimension xn(n), gn(n), bd(*)
	dimension hess(*), inhess(*)
	dimension inda(nelem,2), amat(*)
c
c       Compute the trial point corresponding to the minimum break
c       We use jbreak to put variables that, by rounding errors,
c       are free, on the corresponding bounds. For example, the va-
c       riable alfabreak certainly must be on a bound, but the variables
c       that, perhaps, have a distance to a bound that is less than or
c       equal to the distance of x(jbreak) to its bound, will be also
c       put on the corresponding bound.
c
c
c       Moreover, in dic 4 1995 we decided to put a variable on its bound
c       if the difference between this bound and the variable is less
c       than 1.d-14 (relative error). This modification is present in
c       the version box9512, but not in box9511d. We assume a machine
c       precision around 1.d-16 If the machine precision changes, you
c       must change 1.d-14 consequently.

	do 7 i=1,n
7       xn(i)=x(i)
	do 1 i=1,nfree
	j=infree(i)
	xn(j)=x(j) + alfabreak*d(j)
1       continue
	tole = dmin1(u(jbreak)-xn(jbreak), xn(jbreak)-l(jbreak))
	tole = dmax1(0.d0, tole)
	tole = 1.5d0*tole


c    The following two lines should not be necessary
c    if we neglected rounding errors. See comment above.
	do 10 i=1,nfree
	j=infree(i)
	tolo=dmax1(tole, 1.d-14 * dabs(u(j)))
	if(xn(j).ge.u(j)-tolo) xn(j)=u(j)
	tolo=dmax1(tole, 1.d-14 * dabs(l(j)))
	if(xn(j).le.l(j)+tolo) xn(j)=l(j)
10      continue        
c
c       Compute the gradient at this xn
c
	do 2 i=1,n
2       gn(i)=g(i)+alfabreak*bd(i)
c
c       Compute the functional value at this xn
c
	call fuqu(n, xn, gn, b, fn)

c
c       Copy xn in x, since this new point is necessarily better than
c       the old one
c
	do 3 i=1,nfree
	j=infree(i)
3       x(j)=xn(j)
	alfa=alfabreak
	do 4 i=1,n
4       g(i)=gn(i)
	f=fn
c
c       Initiate de double-step procedure, with the aim of obtaining
c       a point even better
c
9       alfa=factor*alfa
	do 8 i=1,nfree
	j=infree(i)
	xn(j)=x(j)+alfa*d(j)
	if(xn(j).gt.u(j))xn(j)=u(j)
	if(xn(j).lt.l(j))xn(j)=l(j)
8       continue
	call grad(n, mapro, b, xn, gn, mvp, hess, inhess,
     *    mrowsa, ro, reg, ispar, nelem, inda, amat, 
     *    bd(n+1), bd(n+mrowsa+1))      
	call fuqu(n, xn, gn, b, fn)

c       If the doubling step did not improve, return
	if(fn.ge.f)return
	f=fn
	do 5 i=1,nfree
	j=infree(i)
5       x(j)=xn(j)
	do 6 i=1,n
6       g(i)=gn(i)
	goto9
	end


	subroutine roata (n, nfree, infree, d, bd, 
     *     m, ro, reg, ispar, nelem, inda, a, u, v)
	implicit double precision (a-h, o-z)
c
c    This subroutine adds the term ro A^T A d + reg I d to the vector bd
c    See the comments on the use of mapro, and the comments of the
c    calling subroutines for more details on storage of A, etc
c
	dimension d(n), bd(*), inda(nelem,2), a(*), u(*), v(*)
	dimension infree(*)


	if(ispar.eq.0.and.nfree.eq.n)then
c
c    Compute  u  =  A d
c
	do 1 i=1,m
	u(i)=0.d0
	do 1 j=1,n
	k=(j-1)*m+i
c
c    a(k) is   [A]_ij
c
1       u(i)=u(i)+a(k)*d(j)
c
c    Compute A^T u, pre-multiply by ro and add to bd
c
6       do 2 j=1,n
	z=0.d0
	do 3 i=1,m
	k=(j-1)*m+i
c
c    a(k) is   [A]_ij
c

3       z=z+a(k)*u(i)
2       bd(j)=bd(j) + ro*z


	if(reg.ne.0.d0) then
	do 14 i=1,n
14      bd(i)=bd(i)+reg*d(i)
	endif
	return
	endif

	if(ispar.eq.0.and.nfree.lt.n)then
c
c    Compute  u  =  A d
c
	do 5 i=1,m
	u(i)=0.d0
	do 5 k=1,nfree
	j=infree(k)  
	kk=(j-1)*m+i
c
c    a(kk) is   [A]_ij
c
5       u(i)=u(i)+ a(kk)*d(j)
c
c    Compute A^T u, pre-multiply by ro and add to bd
c
	do 7 j=1,n
	z=0.d0
	do 8 i=1,m
	k=(j-1)*m+i
c
c    a(k) is   [A]_ij
c

8       z=z+a(k)*u(i)
7       bd(j)=bd(j) + ro*z


	if(reg.ne.0.d0) then
	do 15 i=1,n
15      bd(i)=bd(i)+reg*d(i)
	endif
	return
	endif
c

	if(ispar.eq.1)then
c
c    Compute  u  =  A d
c
	do 13 i=1,m
13      u(i)=0.d0
	do 9 k=1,nelem
	i=inda(k,1)
	j=inda(k,2)
c
c    a(k) is   [A]_ij
c
9       u(i)=u(i)+a(k)*d(j)
c
c    Compute A^T u, pre-multiply by ro and add to bd
c
	do 10 i=1,n
10      v(i)=0.d0
	do 11 k=1,nelem
	i=inda(k,1)
	j=inda(k,2)
c
c    a(k) is   [A]_ij
c

11      v(j)=v(j) + a(k)*u(i)
	do 12 j=1,n
12      bd(j)=bd(j)+ro*v(j)
	if(reg.ne.0.d0) then
	do 16 i=1,n
16      bd(i)=bd(i)+reg*d(i)
	endif
	return
	endif
c
c       if(ispar.eq.1.and.nfree.lt.n) then ????
c       I do not know how to take advantage of sparsity both in A and
c       d for obtaining the product A d
c
	end


	subroutine pena (n, x, f, g, res, 
     *   m, ila, lambda, ro, ispar, nelem, inda, a, b, aux, modo)
	implicit double precision (a-h,o-z)
	double precision lambda(*)
	dimension x(n), g(n), inda(nelem, 2), a(*), b(*), res(*)
	dimension aux(*)
c
c   This subroutine adds to f the term 
c
c  lambda^T (A x - b) +  (ro/2) || A x - b ||^2 
c
c   if modo = 1  and adds to g the term
c
c      A^T [ lambda + ro (A x - b) ] 
c
c   if modo = 2 .
c
c   We store A x - b in the vector res and we use the fact that, in 
c   BOX a call of pena with modo=2 is always immediately 
c   preceeded by a call with
c   modo=1 so that we can use the values of res computed in modo=1 
c   for the computations for modo=2 .
c
c   See the comments of BOX for the storage of A
c
c
c   Compute the residual vector res
c
	if(modo.eq.1)then
		if(m.gt.0)then
	if(ispar.eq.0)then
	do 1 i=1,m
	res(i) = - b(i)
	do 1 j=1,n
	k=(j-1)*m+i
c
c    a(k)  is  [A]_ij
c
1       res(i)=res(i)+a(k)*x(j)
	else
	do 2 i = 1, m
2       res(i) = - b(i)

	do 3 k = 1, nelem
	i = inda (k, 1)
	j = inda (k, 2)
c
c    a(k)  is  [A]_ij
c
3       res(i) = res(i) + a(k) * x(j)


	endif

	pes=0.d0
	if(ila.eq.1)then
	do 4 i=1,m
4       pes=pes+lambda(i)*res(i)
	endif
	z=0.d0
	do 5 i=1,m
5       z=z+res(i)**2
	f = f + pes + ro * z / 2.d0
		       endif
	return
	else
c  
c    Now, modo = 2
c
	if(m.ne.0)then
	do 7 i=1,m
7       aux(n+i) = lambda(i) + ro*res(i)
c
	do 6 j=1,n
6       aux(j)=0.d0
	if(ispar.eq.0)then
	do 10 j=1,n
	do 10 i=1,m
	k=(j-1)*m+i
10      aux(j)=aux(j)+ a(k)*aux(n+i)
	else
	do 8 k=1,nelem
	i=inda(k,1)
	j=inda(k,2)
8       aux(j)=aux(j)+a(k)*aux(n+i)
	endif
	do 9 j=1,n
9       g(j)=g(j)+aux(j)
	endif
	return
	endif

	end







c
C----------------------------------------------------------------------
C
      	integer function mult( p, q)
C
	Integer p, q, p0, p1, q0, q1
C
	p1 = p/10000
	p0 = mod(p,10000)
	q1 = q/10000
	q0 = mod(q,10000)
	mult = mod( mod( p0*q1+p1*q0,10000)*10000+p0*q0,100000000)
	return
	end
C
C----------------------------------------------------------------------
C
	real*8 function rnd(sem)
C
	integer sem, mult
C
	sem = mod( mult( sem, 3141581) + 1, 100000000)
	rnd = sem/100000000.0d0
	return
	end
C
C----------------------------------------------------------------------


