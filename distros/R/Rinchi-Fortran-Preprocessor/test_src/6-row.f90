PROGRAM  Six_Per_Row
   IMPLICIT  NONE
   INTEGER, PARAMETER         :: SIZE = 20
   INTEGER, DIMENSION(1:SIZE) :: x
   INTEGER                    :: i
   CHARACTER(LEN=80)          :: String

   String = "(1X, A/ 1X, A // (1X, 6I4))"

   DO i = 1, SIZE
      x(i) = MOD(i, 5) + i
   END DO

   WRITE(*,String) 'Generated Table',  &
                   '---------------',  &
                   (x(i), i = 1, SIZE)

END PROGRAM  Six_Per_Row
