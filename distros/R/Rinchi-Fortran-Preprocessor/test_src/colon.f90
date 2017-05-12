PROGRAM  ColonTest
   IMPLICIT  NONE
   INTEGER                      :: i, n
   CHARACTER(LEN=15), PARAMETER :: DashLine = "---------------"
   READ(*,*)  n
   WRITE(*,"(1X,5I3/)")   (i, i = 1, n)
   WRITE(*,"(1X,a)")      DashLine
   WRITE(*,"(1X,5I3:/)")  (i, i = 1, n)
   WRITE(*,"(1X,a)")      DashLine
END PROGRAM  ColonTest
