! --------------------------------------------------------------------
! PROGRAM  ComputeMedian:
!	This program contains an internal REAL function for computing the
! median of a set of input.  The median of a set of N data values is
! defined as follows.  First, the data values must be sorted.  Then,
! the median is the middle value X(N/2+1) if N is odd; otherwise, the
! median is the average of the middle two values (i.e., (X(n)+X(N/2+1))/2).
! For example, the median of 4, 2, 3, 1 is 2.5 since the sorted data
! values are 1, 2, 3 and 4 and the average of the middle two data
! values is (2+3)/2.  The median of 5, 3, 4, 1, 2 is 3 since 3 is the
! middle value of the sorted data 1, 2, 3, 4, 5.
!
! We shall use the sorting subroutine discussed earlier.
! --------------------------------------------------------------------

PROGRAM  ComputeMedian
   USE       Sorting
   IMPLICIT  NONE
   INTEGER, PARAMETER               :: ARRAY_SIZE = 20
   INTEGER, DIMENSION(1:ARRAY_SIZE) :: DataArray
   INTEGER                          :: ActualSize
   INTEGER                          :: IOstatus
   INTEGER                          :: i

   DO
      READ(*,*,IOSTAT=IOstatus) ActualSize, (DataArray(i), i = 1, ActualSize)
      IF (IOstatus < 0) THEN
         WRITE(*,*)  "End of data reached."
         EXIT
      ELSE IF (IOstatus > 0) THEN
         WRITE(*,*)  "Something wrong in your data."
         EXIT
      ELSE
         WRITE(*,*)  "InputData:"
         WRITE(*,*)  (DataArray(i), i = 1, ActualSize)
         WRITE(*,*)
         WRITE(*,*)  "Median = ", Median(DataArray, ActualSize)
         WRITE(*,*)
      END IF
   END DO

CONTAINS

! --------------------------------------------------------------------
! REAL FUNCTION  Median() :
!    This function receives an array X of N entries, copies its value
! to a local array Temp(), sorts Temp() and computes the median.
!    The returned value is of REAL type.
! --------------------------------------------------------------------

   REAL FUNCTION  Median(X, N)
      IMPLICIT  NONE
      INTEGER, DIMENSION(1:), INTENT(IN) :: X
      INTEGER, INTENT(IN)                :: N
      INTEGER, DIMENSION(1:N)            :: Temp
      INTEGER                            :: i

      DO i = 1, N                       ! make a copy
         Temp(i) = X(i)
      END DO
      CALL  Sort(Temp, N)               ! sort the copy
      IF (MOD(N,2) == 0) THEN           ! compute the median
         Median = (Temp(N/2) + Temp(N/2+1)) / 2.0
      ELSE
         Median = Temp(N/2+1)
      END IF
   END FUNCTION  Median

END PROGRAM  ComputeMedian
