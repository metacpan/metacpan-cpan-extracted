! --------------------------------------------------------------------
! PROGRAM  MeanVariance:
!    This program reads in an array and computes the mean, variance
! and standard deviation of the data stored in the array.  Then, it
! displays an analysis table.  If a value is greater than the value 
! of (mean + standard deviation), it displays a "good".  If a value
! is less than the value of (mean - standard deviation), it displays
! a "bad". 
! --------------------------------------------------------------------

PROGRAM  MeanVariance
   IMPLICIT  NONE

   INTEGER, PARAMETER :: MAX_SIZE = 50       ! maximum array size
   REAL, DIMENSION(1:MAX_SIZE) :: Data       ! input array
   REAL               :: Mean, Variance, StdDev   ! results
   INTEGER            :: n                   ! actual array size
   INTEGER            :: i                   ! running index

   READ(*,*)  n                         ! read in input array
   READ(*,*)  (Data(i), i = 1, n)
   WRITE(*,*)  "Input Data:"            ! display the input
   WRITE(*,*)  (Data(i), i = 1, n)
   
   Mean = 0.0                           ! compute mean
   DO i = 1, n
      Mean = Mean + Data(i)
   END DO
   Mean = Mean / n

   Variance = 0.0                       ! compute variance
   DO i = 1, n
      Variance = Variance + (Data(i) - Mean)**2
   END DO
   Variance = Variance / (n - 1)
   StdDev   = SQRT(Variance)            ! compute standard deviation

   WRITE(*,*)                           ! display result
   WRITE(*,*)  "Mean               : ", Mean
   WRITE(*,*)  "Variance           : ", Variance
   WRITE(*,*)  "Standard Deviation : ", StdDev
   WRITE(*,*)
   WRITE(*,*)  "Analysis Table:"        ! display an analysis table
   DO i = 1, n
      IF (Data(i) > Mean + StdDev) THEN 
         WRITE(*,*)  Data(i), Data(i) - Mean, "<-- Good"
      ELSE IF (Data(i) < Mean - StdDev) THEN
         WRITE(*,*)  Data(i), Data(i) - Mean, "<-- Bad"
      ELSE
         WRITE(*,*)  Data(i), Data(i) - Mean
      END IF
   END DO

END PROGRAM  MeanVariance
