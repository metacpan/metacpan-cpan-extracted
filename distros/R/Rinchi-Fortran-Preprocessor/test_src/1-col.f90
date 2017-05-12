PROGRAM  Single_Column
   IMPLICIT  NONE
   INTEGER, PARAMETER             :: MAX_SIZE = 20
   INTEGER, DIMENSION(1:MAX_SIZE) :: x
   INTEGER                        :: i
   CHARACTER(LEN=80)              :: FMT

   DO i = 1, MAX_SIZE
      X(i) = MOD(i, 5) + i
   END DO

   FMT = "(T7, A/ T7, A// T10, A, T15, A/(T10, I2, T15, I4))"
   WRITE(*,FMT)  'Generated Table',   &
                 '---------------',   &
                 'No', 'Data',        &
                 (x(i), i = 1, MAX_SIZE)

END PROGRAM  Single_Column


