! ---------------------------------------------------
!   Solve  Ax^2 + Bx + C = 0 given B*B-4*A*C >= 0   
!   Now, we are able to detect complex roots and
!   repeated roots.
! ---------------------------------------------------
 
PROGRAM  QuadraticEquation
   IMPLICIT  NONE

   REAL  :: a, b, c
   REAL  :: d
   REAL  :: root1, root2
   
!  read in the coefficients a, b and c

   READ(*,*)  a, b, c
   WRITE(*,*) 'a = ', a
   WRITE(*,*) 'b = ', b
   WRITE(*,*) 'c = ', c
   WRITE(*,*)

!  compute the discriminant d

   d = b*b - 4.0*a*c
   IF (d > 0.0) THEN               ! distinct roots?
      d     = SQRT(d)
      root1 = (-b + d)/(2.0*a)     ! first root
      root2 = (-b - d)/(2.0*a)     ! second root
      WRITE(*,*)  'Roots are ', root1, ' and ', root2
   ELSE                           
      IF (d == 0.0) THEN           ! repeated roots?
         WRITE(*,*)  'The repeated root is ', -b/(2.0*a)
      ELSE                         ! complex roots
         WRITE(*,*)  'There is no real roots!'
         WRITE(*,*)  'Discriminant = ', d
      END IF
   END IF

END PROGRAM  QuadraticEquation
