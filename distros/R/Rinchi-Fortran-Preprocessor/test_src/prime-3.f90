! --------------------------------------------------------------------
! Given an integer, this program determines if it is a prime number.
! This program first makes sure the input is 2.  In this case, it is
! a prime number.  Then, it checks to see the input is an even 
! number.  If the input is odd, then this program divides the input
! with 3, 5, 7, ....., until one of two conditions is met:
!    (1)  if one these odd number evenly divides the input, the
!         input is not a prime number;
!    (2)  if the divisor is greater than the square toot of the
!         input, the input is a prime.
!
! A LOGICAL function Prime() is used.  This function takes a positive
! integer and returns .TRUE. if the argument is a prime number;
! otherwise, it returns .FALSE.
! --------------------------------------------------------------------

PROGRAM  PrimeNumber
   IMPLICIT  NONE

   INTEGER  :: Number
   
   READ(*,*)  Number
   IF (Prime(Number)) THEN         ! send Number to Prime() for testing
      WRITE(*,*)  Number, ' is a prime number'
   ELSE
      WRITE(*,*)  Number, ' is not a prime number'
   END IF

CONTAINS

! --------------------------------------------------------------------
! LOGICAL FUNCTION  Prime()
!    This function receives an INTEGER formal argument Number.  If it
! is a prime number, .TRUE. is returned; otherwise, this function
! returns .FALSE.
! --------------------------------------------------------------------

   LOGICAL FUNCTION  Prime(Number)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: Number 
      INTEGER             :: Divisor
   
      IF (Number < 2) THEN
         Prime = .FALSE.
      ELSE IF (Number == 2) THEN
         Prime = .TRUE.
      ELSE IF (MOD(Number,2) == 0) THEN
         Prime = .FALSE.
      ELSE
         Divisor = 3
         DO
            IF (Divisor*Divisor>Number .OR. MOD(Number,Divisor)==0)  EXIT
            Divisor = Divisor + 2
         END DO
         Prime = Divisor*Divisor > Number
      END IF
   END FUNCTION  Prime

END PROGRAM  PrimeNumber
