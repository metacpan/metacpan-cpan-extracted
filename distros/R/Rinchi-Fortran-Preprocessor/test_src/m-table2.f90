PROGRAM  Multiplication_Table
   IMPLICIT  NONE
   INTEGER, PARAMETER :: MAX = 9
   INTEGER            :: i, j
   CHARACTER(LEN=80)  :: FORMAT

   FORMAT = "(9(2X, I1, A, I1, A, I2))"
   WRITE(*,FORMAT) ((i, '*', j, '=', i*j, j = 1, MAX), i = 1, MAX)
END PROGRAM  Multiplication_Table
