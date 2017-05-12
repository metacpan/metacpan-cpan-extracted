! ---------------------------------------------------------
! This program counts the number of positive and negative
! input values and computes their sums.
! ---------------------------------------------------------

PROGRAM  Counting
   IMPLICIT  NONE

   INTEGER :: Positive, Negative       
   INTEGER :: PosSum, NegSum
   INTEGER :: TotalNumber, Count
   INTEGER :: Data

   Positive = 0                    ! # of positive items
   Negative = 0                    ! # of negative items
   PosSum   = 0                    ! sum of all positive items
   NegSum   = 0                    ! sum of all negative items

   READ(*,*)  TotalNumber          ! read in # of items
   DO Count = 1, TotalNumber       ! for each iteration
      READ(*,*)  Data              !    read an item
      WRITE(*,*) 'Input data ', Count, ': ', Data
      IF (Data > 0) THEN           !    if it is positive
         Positive = Positive + 1   !         count it
         PosSum   = PosSum + Data  !         compute their sum
      ELSE IF (Data < 0) THEN      !    if it is negative
         Negative = Negative + 1   !         count it
         NegSum   = NegSum + Data  !         compute their sum
      END IF
   END DO

   WRITE(*,*)                      ! display results
   WRITE(*,*)  'Counting Report:'
   WRITE(*,*)  '   Positive items = ', Positive, ' Sum = ', PosSum
   WRITE(*,*)  '   Negative items = ', Negative, ' Sum = ', NegSum
   WRITE(*,*)  '   Zero items     = ', TotalNumber - Positive - Negative
   WRITE(*,*)
   WRITE(*,*)  'The total of all input is ', Positive + Negative

END PROGRAM  Counting
