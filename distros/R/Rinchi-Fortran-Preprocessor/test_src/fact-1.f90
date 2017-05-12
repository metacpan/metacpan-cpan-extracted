MODULE  FactorialModule
   IMPLICIT  NONE

CONTAINS
  
   INTEGER FUNCTION  Factorial(N)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: N
      INTEGER             :: Fact, i

      Fact = 1
      DO i = 1, N
         Fact = Fact * i
      END DO
      Factorial = Fact

   END FUNCTION  Factorial

   INTEGER FUNCTION  Combinatorial(N, R)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: N, R
      INTEGER             :: Cnr

      IF (0 <= R .AND. R <= N) THEN
         Cnr = Factorial(N) / (Factorial(R)*Factorial(N-R))
      ELSE
         Cnr = 0
      END IF
      Combinatorial = Cnr

   END FUNCTION  Combinatorial

END MODULE  FactorialModule
