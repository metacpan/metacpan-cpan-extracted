PROGRAM  InnerProduct
   IMPLICIT  NONE
   INTEGER, PARAMETER         :: SIZE = 50
   INTEGER                    :: Number, Sum, i
   INTEGER, DIMENSION(1:SIZE) :: x, y
   CHARACTER(LEN=80)          :: Fmt1, Fmt2, Fmt3

   Fmt1 = "(I5/(2I5))"
   Fmt2 = "(1X,A//1X,3A5/(1X,3I5))"
   Fmt3 = "(/1X, A, I7)"

   READ(*,Fmt1)   Number, (x(i), y(i), i = 1, Number)
   WRITE(*,Fmt2)  "Input Data", "No", "X", "Y", &
                  (i, x(i), y(i), i = 1, Number)
   Sum = 0
   DO i = 1, Number
      Sum = Sum + x(i)*y(i)
   END DO
   WRITE(*,Fmt3)  "Input product = ", Sum
END PROGRAM  InnerProduct
