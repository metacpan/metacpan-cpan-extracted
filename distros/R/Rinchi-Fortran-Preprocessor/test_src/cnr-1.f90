! ---------------------------------------------------------------
! This program computes the combinatorial coefficient C(n,r):
!
!                       n!
!         C(n,r) = -------------
!                   r! x (n-r)!
!
! It asks for two integers and uses Cnr(n,r) to compute the value.
! If 0 <= r <= n does not hold, Cnr() returns -1 so that the main
! program would know the input values are incorrect.  Otherwise,
! Cnr() returns the desired combinatorial coefficient.
!
! Note that if the input values are zeros, this program stops.
! ---------------------------------------------------------------

PROGRAM  Combinatorial
   IMPLICIT   NONE

   INTEGER :: n, r, Answer

   DO
      WRITE(*,*)
      WRITE(*,*)  "Two integers n and r (0 <= r <= n) please "
      WRITE(*,*)  "0 0 to stop --> "
      READ(*,*)   n, r
      IF (n == 0 .AND. r == 0)  EXIT
      WRITE(*,*)  "Your input:"
      WRITE(*,*)  "  n      = ", n
      WRITE(*,*)  "  r      = ", r
      Answer = Cnr(n, r)
      IF (Answer < 0) THEN
         WRITE(*,*)  "Incorrect input"
      ELSE
         WRITE(*,*) "  C(n,r) = ", Answer
      END IF
   END DO

CONTAINS

! ---------------------------------------------------------------
! INTEGER FUNCTION  Cnr(n,r)
!    This function receives n and r, uses LOGICAL function Test()
! to verify if the condition 0 <= r <= n holds, and uses
! Factorial() to compute n!, r! and (n-r)!.
! ---------------------------------------------------------------

   INTEGER FUNCTION  Cnr(n, r)
      IMPLICIT  NONE
      INTEGER, INTENT(IN) :: n, r

      IF (Test(n,r)) THEN
         Cnr = Factorial(n)/(Factorial(r)*Factorial(n-r))
      ELSE
         Cnr = -1
      END IF
   END FUNCTION  Cnr

! ---------------------------------------------------------------
! LOGICAL FUNCTION  Test()
!    This function receives n and r.  If 0 <= r <= n holds, it
! returns .TRUE.; otherwise, it returns .FALSE.
! ---------------------------------------------------------------

   LOGICAL FUNCTION  Test(n, r)
      IMPLICIT  NONE
      INTEGER, INTENT(IN) :: n, r

      Test = (0 <= r) .AND. (r <= n)
   END FUNCTION  Test

! ---------------------------------------------------------------
! INTEGER FUNCTION  Factorial()
!    This function receives a non-negative integer and computes
! its factorial.
! ---------------------------------------------------------------

   INTEGER FUNCTION  Factorial(k)
      IMPLICIT  NONE
      INTEGER, INTENT(IN) :: k
      INTEGER             :: Ans, i

      Ans = 1
      DO i = 1, k
         Ans = Ans * i
      END DO
      Factorial = Ans
   END FUNCTION  Factorial

END PROGRAM  Combinatorial
