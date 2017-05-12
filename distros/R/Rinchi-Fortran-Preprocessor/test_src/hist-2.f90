PROGRAM  VerticalBarChart
   IMPLICIT  NONE
   CHARACTER(LEN=*), PARAMETER  :: Part1 = "(1X, I5, A,"
   CHARACTER(LEN=*), PARAMETER  :: Part2 = "A, A, I2, A)"
   CHARACTER(LEN=2)             :: Repetition
   CHARACTER(LEN=10), PARAMETER :: InputFormat = "(I5/(5I5))"
   INTEGER                      :: Number, i, j
   INTEGER, DIMENSION(1:100)    :: Data

   READ(*,InputFormat)  Number, (Data(i), i=1, Number)
   DO i = 1, Number
      IF (Data(i) /= 0) THEN
         WRITE(Repetition,"(I2)")  Data(i)
         WRITE(*,Part1 // Repetition // Part2)  Data(i), " |", ("*", j=1,Data(i)), " (", Data(i), ")"
      ELSE
         WRITE(*,"(1X, I5, A, I2, A)")  Data(i), " | (", Data(i), ")"
      END IF
   END DO
END PROGRAM  VerticalBarChart
