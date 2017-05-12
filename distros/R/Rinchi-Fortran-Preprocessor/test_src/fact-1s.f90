PROGRAM  ComputeFactorial
   USE       FactorialModule

   IMPLICIT  NONE

   INTEGER :: N, R

   WRITE(*,*)  'Two non-negative integers --> '
   READ(*,*)   N, R

   WRITE(*,*)  N,   '! = ', Factorial(N)
   WRITE(*,*)  R,   '! = ', Factorial(R)

   IF (R <= N) THEN
      WRITE(*,*)  'C(', N, ',', R, ') = ', Combinatorial(N, R)
   ELSE
      WRITE(*,*)  'C(', R, ',', N, ') = ', Combinatorial(R, N)
   END IF

END PROGRAM  ComputeFactorial
