! ---------------------------------------------------
!   Solve  Ax^2 + Bx + C = 0 given B*B-4*A*C >= 0   
! ---------------------------------------------------
 
PROGRAM  QuadraticEquation
   IMPLICIT  NONE

   REAL  :: a, b, c
   REAL  :: d
   REAL  :: root1, root2
   
!  read in the coefficients a, b and c

   WRITE(*,*) 'A, B, C Please : '
   READ(*,*)  a, b, c

!  compute the square root of discriminant d

   d  = SQRT(b*b - 4.0*a*c)
   
!  solve the equation

   root1 = (-b + d)/(2.0*a)   ! first root
   root2 = (-b - d)/(2.0*a)   ! second root

!  display the results

   WRITE(*,*)
   WRITE(*,*)  'Roots are ', root1, ' and ', root2

END PROGRAM  QuadraticEquation
