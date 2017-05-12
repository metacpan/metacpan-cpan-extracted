! --------------------------------------------------------------------
! PROGRAM  ComputeFactorial:
!    This program uses MODULE FactorialModule for computing factorial
! and combinatorial coefficients.
! --------------------------------------------------------------------

PROGRAM  ComputeFactorial
   USE       FactorialModule            ! use a module

   IMPLICIT  NONE

   INTEGER :: N, R                     

   WRITE(*,*)  'Two non-negative integers --> '
   READ(*,*)   N, R

   WRITE(*,*)  N,   '! = ', Factorial(N)
   WRITE(*,*)  R,   '! = ', Factorial(R)

   IF (R <= N) THEN                     ! if r <= n, do C(n,r)
      WRITE(*,*)  'C(', N, ',', R, ') = ', Combinatorial(N, R)
   ELSE                                 ! otherwise, do C(r,n)
      WRITE(*,*)  'C(', R, ',', N, ') = ', Combinatorial(R, N)
   END IF

END PROGRAM  ComputeFactorial
