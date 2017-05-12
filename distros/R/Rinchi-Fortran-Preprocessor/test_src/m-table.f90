PROGRAM  Multiplication_Table
   IMPLICIT  NONE
   INTEGER, PARAMETER :: MAX = 9
   INTEGER            :: i, j
   CHARACTER(LEN=80)  :: FORMAT

   FORMAT = "(9(2X, I1, A, I1, A, I2))"
   DO i = 1, MAX
      WRITE(*,FORMAT) (i, '*', j, '=', i*j, j = 1, MAX)
   END DO
END PROGRAM  Multiplication_Table
