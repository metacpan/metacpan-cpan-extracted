! --------------------------------------------------------------------
! PROGRAM  Score_Distribution:
!	Give a set of scores, this program plots a histogram showing the
! number of score in the range of [0,59], [60,69], [70,79], [80,89]
! and [90,100].  The range values (i.e., 60, 70, 80 and 90) are read
! in as input data.  The counting and printing subroutines are moved
! to module Histogram_and_Count in file histo-2m.f90.
! --------------------------------------------------------------------

PROGRAM  Score_Distribution
   USE  Histogram_and_Count
   IMPLICIT   NONE
   INTEGER, PARAMETER         :: SIZE = 20   ! array size
   INTEGER, DIMENSION(1:SIZE) :: Score       ! array containing scores
   INTEGER                    :: ActualSize  ! the # of scores read in
   INTEGER, PARAMETER         :: RANGE_SIZE = 10  ! score range size
   INTEGER, DIMENSION(1:RANGE_SIZE) :: Range ! range of scores
   INTEGER                    :: ActualRange
   INTEGER                    :: i

   READ(*,*)  ActualSize, (Score(i), i = 1, ActualSize)
   WRITE(*,*) "Input Scores:"
   WRITE(*,*) (Score(i), i = 1, ActualSize)
   WRITE(*,*)

   READ(*,*)  ActualRange, (Range(i), i = 1, ActualRange)
   WRITE(*,*) "Input Range:"
   WRITE(*,*) (Range(i), i = 1, ActualRange)
   WRITE(*,*)

   CALL  Distribute(Score, ActualSize, Range, ActualRange)

END PROGRAM  Score_Distribution
