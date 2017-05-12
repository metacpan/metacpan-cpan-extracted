! --------------------------------------------------------------------
! MODULE  FactorialModule
!    This module contains two procedures: Factorial(n) and 
! Combinatorial(n,r).  The first computes the factorial of an integer 
! n and the second computes the combinatorial coefficient of two 
! integers n and r.
! --------------------------------------------------------------------

MODULE  FactorialModule
   IMPLICIT  NONE

CONTAINS

! --------------------------------------------------------------------
! FUNCTION  Factorial() :
!    This function accepts a non-negative integers and returns its
! Factorial.
! --------------------------------------------------------------------
  
   INTEGER FUNCTION  Factorial(n)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: n          ! the argument
      INTEGER             :: Fact, i    ! result

      Fact = 1                          ! initially, n!=1
      DO i = 1, n                       ! this loop multiplies
         Fact = Fact * i                ! i to n!
      END DO
      Factorial = Fact                  

   END FUNCTION  Factorial

! --------------------------------------------------------------------
! FUNCTION  Combinarotial():
!    This function computes the combinatorial coefficient C(n,r).
! If 0 <= r <= n, this function returns C(n,r), which is computed as
! C(n,r) = n!/(r!*(n-r)!).  Otherwise, it returns 0, indicating an
! error has occurred.
! --------------------------------------------------------------------

   INTEGER FUNCTION  Combinatorial(n, r)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: n, r
      INTEGER             :: Cnr

      IF (0 <= r .AND. r <= n) THEN     ! valid arguments ?
         Cnr = Factorial(n) / (Factorial(r)*Factorial(n-r))
      ELSE                              ! no,
         Cnr = 0                        ! zero is returned
      END IF
      Combinatorial = Cnr

   END FUNCTION  Combinatorial

END MODULE  FactorialModule
