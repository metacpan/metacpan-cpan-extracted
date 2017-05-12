! ---------------------------------------------------------
! This program computes the GCD of two positive integers
! using the Euclid method.  Given a and b, a >= b, the 
! Euclid method goes as follows:  (1) dividing a by b yields 
! a reminder c; (2) if c is zero, b is the GCD; (3) if c is
! no zero, b becomes a and c becomes c and go back to
! Step (1).  This process will continue until c is zero.
!
! Euclid's algorithm is implemented as an INTEGER function
! GCD().
! ---------------------------------------------------------

PROGRAM  GreatestCommonDivisor
   IMPLICIT  NONE

   INTEGER   :: a, b

   WRITE(*,*) 'Two positive integers please --> '
   READ(*,*)  a, b
   WRITE(*,*) 'The GCD of is ', GCD(a, b)

CONTAINS

! ---------------------------------------------------------
! INTEGER FUNCTION  GCD():
!    This function receives two INTEGER arguments and
! computes their GCD.
! ---------------------------------------------------------

   INTEGER FUNCTION  GCD(x, y)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: x, y       ! we need x and y here
      INTEGER             :: a, b, c

      a = x                   ! if x <= y, swap x and y
      b = y                   ! since x and y are declared with
      IF (a <= b) THEN        ! INTENT(IN), they cannot be 
         c = a                ! involved in this swapping process.
         a = b                ! So, a, b and c are used instead.
         b = c
      END IF

      DO              
         c = MOD(a, b)
         IF (c == 0) EXIT
         a = b           
         b = c           
      END DO             

      GCD = b
   END FUNCTION  GCD

END PROGRAM  GreatestCommonDivisor
