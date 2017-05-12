! ---------------------------------------------------------
! This program computes exp(x) for an input x using the 
! infinite series of exp(x).  This program adds the 
! terms together until a term is less than a specified
! tolerance value.  Thus, two values are required:
! the value for x and a tolerance value.  In this program,
! he tolerance value is set to 0.00001 using PARAMETER.
! ---------------------------------------------------------

PROGRAM  Exponential
   IMPLICIT  NONE

   INTEGER         :: Count             ! # of terms used
   REAL            :: Term              ! a term
   REAL            :: Sum               ! the sum of series
   REAL            :: X                 ! the input x
   REAL, PARAMETER :: Tolerance = 0.00001    ! tolerance

   READ(*,*)  X                         ! read in x
   Count = 1                            ! the first term is 1 and counted
   Sum   = 1.0                          ! thus, the sum starts with 1
   Term  = X                            ! the second term is x
   DO                                   ! for each term
      IF (ABS(Term) < Tolerance)  EXIT  !    if too small, exit
      Sum   = Sum + Term                !    otherwise, add to sum
      Count = Count + 1                 !    count indicates the next term
      Term  = Term * (X / Count)        !    compute the value of next term
   END DO

   WRITE(*,*)  'After ', Count, ' iterations:'
   WRITE(*,*)  '  Exp(', X, ') = ', Sum
   WRITE(*,*)  '  From EXP()   = ', EXP(X)
   WRITE(*,*)  '  Abs(Error)   = ', ABS(Sum - EXP(X))

END PROGRAM  Exponential
