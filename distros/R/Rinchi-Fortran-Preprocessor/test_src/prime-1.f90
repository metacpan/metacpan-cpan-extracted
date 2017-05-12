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
! --------------------------------------------------------------------

PROGRAM  Prime
   IMPLICIT  NONE

   INTEGER  :: Number                   ! the input number
   INTEGER  :: Divisor                  ! the running divisor
   
   READ(*,*)  Number                    ! read in the input
   IF (Number < 2) THEN                 ! not a prime if < 2
      WRITE(*,*)  'Illegal input'
   ELSE IF (Number == 2) THEN           ! is a prime if = 2
      WRITE(*,*)  Number, ' is a prime'    
   ELSE IF (MOD(Number,2) == 0) THEN    ! not a prime if even
      WRITE(*,*)  Number, ' is NOT a prime'
   ELSE                                 ! we have an odd number here
      Divisor = 3                       ! divisor starts with 3
      DO                                ! divide the input number
         IF (Divisor*Divisor > Number .OR. MOD(Number, Divisor) == 0)  EXIT
         Divisor = Divisor + 2          ! increase to next odd
      END DO
      IF (Divisor*Divisor > Number) THEN     ! which condition fails?
         WRITE(*,*)  Number, ' is a prime'   
      ELSE
         WRITE(*,*)  Number, ' is NOT a prime'
      END IF
   END IF
END PROGRAM  Prime
