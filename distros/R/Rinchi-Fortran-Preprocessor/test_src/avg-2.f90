PROGRAM  Mean
   IMPLICIT  NONE
   INTEGER, PARAMETER         :: SIZE = 20
   REAL, DIMENSION(1:SIZE)    :: x
   INTEGER                    :: ActualSize
   INTEGER                    :: i
   REAL                       :: Average
   CHARACTER(LEN=30)          :: Title = "(A, A)"

   READ(*,*)  ActualSize
   READ(*,*)  (x(i), i = 1, ActualSize)

   Average = 0.0
   DO i = 1, ActualSize
      Average = Average + x(i)
   END DO
   Average = Average / ActualSize

   WRITE(*,Title)  " ", "Average Computation"
   WRITE(*,Title)  " "
   WRITE(*,Title)  " ", "Input Data"
   WRITE(*,Title)  " "
   WRITE(*,Title)  " ", " No  Data "
   WRITE(*,Title)  " ", "=== ======"
   WRITE(*,"(I4, F7.2)")  (i, x(i), i = 1, ActualSize)
   WRITE(*,Title)  " "
   WRITE(*,"(A,A,ES15.7)")  " ", "Average = ", Average
END PROGRAM  Mean
