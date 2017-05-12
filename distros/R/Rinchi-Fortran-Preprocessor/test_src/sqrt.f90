! ---------------------------------------------------------
! This program uses Newton's method to find the square
! root of a positive number.  This is an iterative method
! and the program keeps generating better approximation
! of the square root until two successive approximations
! have a distance less than the specified tolerance.
! ---------------------------------------------------------

PROGRAM  SquareRoot
   IMPLICIT  NONE

   REAL    :: Input, X, NewX, Tolerance
   INTEGER :: Count

   READ(*,*)  Input, Tolerance

   Count = 0                            ! count starts with 0
   X     = Input                        ! X starts with the input value
   DO                                   ! for each iteration
      Count = Count + 1                 !    increase the iteration count
      NewX  = 0.5*(X + Input/X)         !    compute a new approximation
      IF (ABS(X - NewX) < Tolerance)  EXIT   ! if they are very close, exit
      X = NewX                          !    otherwise, keep the new one
   END DO

   WRITE(*,*)  'After ', Count, ' iterations:'
   WRITE(*,*)  '  The estimated square root is ', NewX
   WRITE(*,*)  '  The square root from SQRT() is ', SQRT(Input)
   WRITE(*,*)  '  Absolute error = ', ABS(SQRT(Input) - NewX)

END PROGRAM  SquareRoot
