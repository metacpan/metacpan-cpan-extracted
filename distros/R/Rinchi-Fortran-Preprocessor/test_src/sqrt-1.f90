! ---------------------------------------------------------------
! This program contains a function MySqrt() that uses Newton's 
! method to find the square root of a positive number.  This is 
! an iterative method and the program keeps generating better  
! approximation of the square root until two successive 
! approximations have a distance less than the specified tolerance.
! ---------------------------------------------------------------

PROGRAM  SquareRoot
   IMPLICIT  NONE

   REAL    :: Begin, End, Step          
   REAL    :: x, SQRTx, MySQRTx, Error

   READ(*,*)  Begin, End, Step          ! read in init, final and step
   x = Begin                            ! x starts with the init value
   DO
      IF (x > End)  EXIT                ! exit if x > the final value
      SQRTx   = SQRT(x)                 ! find square root with SQRT()
      MySQRTx = MySqrt(x)               ! do the same with my sqrt()
      Error   = ABS(SQRTx - MySQRTx)    ! compute the absolute error
      WRITE(*,*)  x, SQRTx, MySQRTx, Error   ! display the results
      x = x + Step                      ! move on to the next value
   END DO

CONTAINS

! ---------------------------------------------------------------
! REAL FUNCTION  MySqrt()
!    This function uses Newton's method to compute an approximate
! of a positive number.  If the input value is zero, then zero is
! returned immediately.  For convenience, the absolute value of
! the input is used rather than kill the program when the input
! is negative.
! ---------------------------------------------------------------

   REAL FUNCTION  MySqrt(Input)
      IMPLICIT  NONE
      REAL, INTENT(IN) :: Input
      REAL             :: X, NewX
      REAL, PARAMETER  :: Tolerance = 0.00001

      IF (Input == 0.0) THEN            ! if the input is zero
         MySqrt = 0.0                   !    returns zero
      ELSE                              ! otherwise,
         X = ABS(Input)                 !    use absolute value
         DO                             !    for each iteration
            NewX  = 0.5*(X + Input/X)   !       compute a new approximation
            IF (ABS(X - NewX) < Tolerance)  EXIT  ! if very close, exit
            X = NewX                    !       otherwise, keep the new one
         END DO
         MySqrt = NewX
      END IF
   END FUNCTION  MySqrt

END PROGRAM  SquareRoot
