! --------------------------------------------------------------
! This program computes exp(x) for a range of x.  The range
! is in the form of beginning value, final value and step size.
! For each value in this range, the infinite series of exp(x)
! is used to compute exp(x) up to a tolerance of 0.00001.
! This program display the value of x, the exp(x) from infinite
! series, the exp(x) from Fortran's intrinsic function exp(x),
! the absolute error, and the relative error.
! --------------------------------------------------------------

PROGRAM  Exponential
   IMPLICIT  NONE

   INTEGER         :: Count             ! term count
   REAL            :: Term              ! a term
   REAL            :: Sum               ! the sum of series
   REAL            :: X                 ! running value
   REAL            :: ExpX              ! EXP(X)
   REAL            :: Begin, End, Step  ! control values
   REAL, PARAMETER :: Tolerance = 0.00001    ! tolerance

   WRITE(*,*)  'Initial, Final and Step please --> '
   READ(*,*)   Begin, End, Step

   X = Begin                            ! X starts with the beginning value
   DO
      IF (X > End)  EXIT                ! if X is > the final value, EXIT
      Count = 1                         ! the first term is 1 and counted
      Sum   = 1.0                       ! thus, the sum starts with 1
      Term  = X                         ! the second term is x
      ExpX  = EXP(X)                    ! the exp(x) from Fortran's EXP()
      DO                                ! for each term
         IF (ABS(Term) < Tolerance)  EXIT ! if too small, exit
         Sum   = Sum + Term             !   otherwise, add to sum
         Count = Count + 1              !   count indicates the next term
         Term  = Term * (X / Count)     !   compute the value of next term
      END DO

      WRITE(*,*)  X, Sum, ExpX, ABS(Sum-ExpX), ABS((Sum-ExpX)/ExpX)

      X = X + Step
   END DO

END PROGRAM  Exponential
