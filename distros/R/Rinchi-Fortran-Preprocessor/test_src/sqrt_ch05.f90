PROGRAM  Squares_and_Roots
   IMPLICIT  NONE
   INTEGER, PARAMETER :: MAXIMUM = 10
   INTEGER            :: i
   CHARACTER(LEN=30)  :: Format
   
   Format = "(3I6, 2F12.7)"
   DO i = 1, MAXIMUM
      WRITE(*,Format)  i, i*i, i*i*i, SQRT(REAL(i)), SQRT(SQRT(REAL(i)))
   END DO
END PROGRAM  Squares_and_Roots
