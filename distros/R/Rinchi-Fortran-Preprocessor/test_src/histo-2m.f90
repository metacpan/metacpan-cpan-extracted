! --------------------------------------------------------------------
! MODULE  Histogram_and_Count:
!	This module implements the counting and histogram printing.  Note
! that for the counting part, handled by subroutine Distribute(), two
! more arguments for the range array and its number of entries.  The
! Plot() subroutine now prints a vertical bar histogram.
! --------------------------------------------------------------------

MODULE  Histogram_and_Count
   IMPLICIT  NONE

CONTAINS

! --------------------------------------------------------------------
! SUBROUTINE  Distribute() :
!    This subroutine receives a score array and a range array, counts
! the number of each scores in each range, and calls Plot() to print
! a histogram.
! --------------------------------------------------------------------

   SUBROUTINE  Distribute(X, N, Range, M)
      IMPLICIT NONE
      INTEGER, DIMENSION(1:), INTENT(IN) :: X     ! input score
      INTEGER, INTENT(IN)                :: N     ! # of scores
      INTEGER, DIMENSION(1:), INTENT(IN) :: Range ! range array
      INTEGER, INTENT(IN)                :: M     ! # of ranges
      INTEGER                            :: i, j
      INTEGER, DIMENSION(1:M+1)          :: Bucket! counting bucket

      DO i = 1, M+1                     ! clear buckets
         Bucket(i) = 0
      END DO

      DO i = 1, N                       ! for each input score
         DO j = 1, M                    ! determine the bucket
            IF (X(i) < Range(j)) THEN
               Bucket(j) = Bucket(j) + 1
               EXIT
            END IF
         END DO                         ! don't forget the last bucket
         IF (X(i) >= Range(M))  Bucket(M+1) = Bucket(M+1)+1
      END DO
      CALL  Plot(Bucket, M+1)           ! print a histogram
   END SUBROUTINE  Distribute

! --------------------------------------------------------------------
! SUBROUTINE  Plot() :
!    This subroutine receives a counting array and prints a vertical
! bar histogram.
! --------------------------------------------------------------------

   SUBROUTINE  Plot(Count, K)
      IMPLICIT NONE
      INTEGER, DIMENSION(1:), INTENT(IN) :: Count
      INTEGER, INTENT(IN)                :: K
      CHARACTER(LEN=4), DIMENSION(1:K)   :: Line
      CHARACTER(LEN=4), PARAMETER        :: Division  = "---+"
      CHARACTER(LEN=4), PARAMETER        :: Empty     = "    "
      CHARACTER(LEN=4), PARAMETER        :: EmptyLast = "   |"
      CHARACTER(LEN=4), PARAMETER        :: Data      = "*** "
      CHARACTER(LEN=4), PARAMETER        :: DataLast  = "***|"
      INTEGER                            :: i, j, Maximum

      Maximum = Count(1)                ! find the maximum of the count
      Line(1) = Division                ! clear the print line
      DO i = 2, K
         Line(i) = Division
         IF (Maximum < Count(i))  Maximum = Count(i)
      END DO

      WRITE(*,*) "Histogram:"
      WRITE(*,*)
      WRITE(*,*) "+", (Line(j), j=1,K)  ! print the top border
      DO i = Maximum, 1, -1             ! print from the top
         DO j = 1, K                    ! for each count value
            IF (Count(j) >= i) THEN     !   if >= current value, show ***
               IF (j == K) THEN         !     if this is the last bar
                  Line(j) = DataLast    !       use "***|"
               ELSE                     !     otherwise
                  Line(j) = Data        !       use "*** "
               END IF
            ELSE                        !   if < current value , don't show
               IF (j == K) THEN         !     if this is the last bar
                  Line(j) = EmptyLast   !       use "   |"
               ELSE                     !     otherwise
                  Line(j) = Empty       !       use "    "
               END IF
            END IF
         END DO
         WRITE(*,*) "|", (Line(j), j=1,K)    ! all done.  display this line
      END DO

      DO j = 1, K                       ! prepare and display the lower border
         Line(j) = Division
      END DO
      WRITE(*,*) "+", (Line(j), j=1,K)
   END SUBROUTINE  Plot

END MODULE  Histogram_and_Count
