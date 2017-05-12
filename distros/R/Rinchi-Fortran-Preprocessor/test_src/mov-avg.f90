! --------------------------------------------------------------------
! PROGRAM  MovingAverage:
!    This program reads in a set of input values and a window value,
! and computes the moving average of the input.  Let the values be
! x1, x2, x3, ..., xn and the window value is k.
! --------------------------------------------------------------------

PROGRAM  MovingAverage
   IMPLICIT  NONE
  
   INTEGER, PARAMETER :: MAX_SIZE = 30       ! array size
   REAL, DIMENSION(1:MAX_SIZE) :: x, Avg     ! arrays
   REAL               :: Sum                 ! for computation use
   INTEGER            :: Window              ! window size
   INTEGER            :: Size                ! actual array size
   INTEGER            :: i, j                ! indices

   READ(*,*)  Size, (x(i), i = 1, Size)      ! read in input data
   READ(*,*)  Window                         ! read in window value
   
   WRITE(*,*) "**********************************"     ! display input
   WRITE(*,*) "*   Moving Average Computation   *"
   WRITE(*,*) "**********************************"
   WRITE(*,*)
   WRITE(*,*) "Input Array:"
   WRITE(*,*) (x(i), i = 1, Size)
   WRITE(*,*)
   WRITE(*,*) "Window Size = ", Window

   DO i = 1, Size-Window+1                   ! for each xi
      Sum = 0.0                              ! compute the moving average
      DO j = i, i+Window-1                   ! of xi, x(i+1), ..., 
         Sum = Sum + x(j)                    ! x(i+Window-1).
      END DO
      Avg(i) = Sum / Window                  ! save the result
   END DO

   WRITE(*,*)                                ! display the result
   WRITE(*,*)  "Moving Average of the Given Array:"
   WRITE(*,*)  (Avg(i), i = 1, Size-Window+1)
END PROGRAM  MovingAverage
