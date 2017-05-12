! --------------------------------------------------------------------
! PROGRAM  Histogram:
!    Given a set of scores, this program plots a histogram showing the
! number of score in the range of [0,59], [60,69], [70,79], [80,89]
! and [90,100].  In subroutine Distribute() a local array is used
! to store these counts which is, in turn, sent to subroutine
! Plot() for plotting.
! --------------------------------------------------------------------

PROGRAM  Histogram
   IMPLICIT NONE
   INTEGER, PARAMETER         :: SIZE = 20   ! array size
   INTEGER, DIMENSION(1:SIZE) :: Score       ! array containing scores
   INTEGER                    :: ActualSize  ! the # of scores read in
   INTEGER                    :: i

   READ(*,*)  ActualSize, (Score(i), i = 1, ActualSize)
   WRITE(*,*) "Input Scores:"
   WRITE(*,*) (Score(i), i = 1, ActualSize)
   WRITE(*,*)

   CALL  Distribute(Score, ActualSize)

CONTAINS

! --------------------------------------------------------------------
! SUBROUTINE  Distribute() :
!    This subroutine receives a set of scores and count the number of
! scores in the range of [0,59], [60,69], [70,79], [80,89] and
! [90,100].  A local array is used to accumulate these counts.
! --------------------------------------------------------------------

   SUBROUTINE  Distribute(X, N)
      IMPLICIT NONE
      INTEGER, DIMENSION(1:), INTENT(IN) :: X
      INTEGER, INTENT(IN)                :: N
      INTEGER, PARAMETER                 :: Bucket_Size = 5
      INTEGER, DIMENSION(1:Bucket_Size)  :: Bucket
      INTEGER                            :: i

      DO i = 1, Bucket_Size             ! clear the local array
         Bucket(i) = 0
      END DO

      DO i = 1, N                       ! for each score ...
         SELECT CASE (X(i))             !    determine the range it lies
            CASE (:59)
               Bucket(1) = Bucket(1) + 1
            CASE (60:69)
               Bucket(2) = Bucket(2) + 1
            CASE (70:79)
               Bucket(3) = Bucket(3) + 1
            CASE (80:89)
               Bucket(4) = Bucket(4) + 1
            CASE (90:)
               Bucket(5) = Bucket(5) + 1
         END SELECT
      END DO
      CALL  Plot(Bucket, Bucket_Size)   ! send the count to Plot()
   END SUBROUTINE  Distribute

! --------------------------------------------------------------------
! SUBROUTINE  Plot() :
!    This subroutine receives a set of count from an array and for
! each count, displays that number of '*'s on the same line.  Thus,
! the result is a histogram.
! --------------------------------------------------------------------

   SUBROUTINE  Plot(Input, Size)
      IMPLICIT NONE
      INTEGER, DIMENSION(1:), INTENT(IN) :: Input
      INTEGER, INTENT(IN)                :: Size
      INTEGER                            :: i, j

      WRITE(*,*) "Histogram:"
      WRITE(*,*)
      DO i = 1, Size
         WRITE(*,*)  ('*', j=1,Input(i)), ' (', Input(i), ')'
      END DO
   END SUBROUTINE  Plot

END PROGRAM  Histogram
