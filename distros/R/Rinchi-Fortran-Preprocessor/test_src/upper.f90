PROGRAM  UpperTriangularMatrix
   IMPLICIT   NONE
   INTEGER, PARAMETER                :: SIZE = 10
   INTEGER, DIMENSION(1:SIZE,1:SIZE) :: Matrix
   INTEGER                           :: Number
   INTEGER                           :: Position
   INTEGER                           :: i, j
   CHARACTER(LEN=100)                :: Format

   READ(*,"(I5)")  Number
   DO i = 1, Number
      READ(*,"(10I5)")  (Matrix(i,j), j = 1, Number)
   END DO

   WRITE(*,"(1X,A)")  "Input Matrix:"
   DO i = 1, Number
      WRITE(*,"(1X,10I5)")  (Matrix(i,j), j = 1, Number)
   END DO

   WRITE(*,"(/1X,A)") "Upper Triangular Part:"
   Position = 2
   DO i = 1, Number
      WRITE(Format,"(A,I2.2,A)")  "(T", Position, ", 10I5)"
      WRITE(*,Format)  (Matrix(i,j), j = i, Number)
      Position = Position + 5
   END DO
END PROGRAM  UpperTriangularMatrix
