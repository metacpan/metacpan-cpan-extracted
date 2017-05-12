PROGRAM  Smoothing
   IMPLICIT  NONE
   INTEGER, PARAMETER           :: MAX_SIZE = 20
   REAL, DIMENSION(1:MAX_SIZE)  :: x, y
   INTEGER                      :: Number
   INTEGER                      :: i
   CHARACTER(LEN=*), PARAMETER  :: TitleHeading  = "T14,A/T14,A/T14,A//T2,A,T28,A/T2,A,T28,A/"
   CHARACTER(LEN=*), PARAMETER  :: NA_Line       = "T2,I3,F10.2,A10,I6,2F10.2/"
   CHARACTER(LEN=*), PARAMETER  :: Data_Line     = "(1X,I3,2F10.2,I6,2F10.2)"
   CHARACTER(LEN=100)           :: Format

   READ(*,"(I5)")  Number
   READ(*,"(5F10.0)")  (x(i), i=1, Number)
   DO i = 1, Number-1
      y(i) = (x(i) + x(i+1)) / 2.0
   END DO

   Format = "(" // TitleHeading // NA_Line // Data_Line // ")"
   WRITE(*,Format)  "**************************",             &
                    "*  Data Smoothing Table  *",             &
                    "**************************",             &
                    (" No       x         y    ", i = 1, 2),  &
                    ("---  --------  --------  ", i = 1, 2),  &
                    1, x(1), "NA", 2, x(2), y(1),             &
                    (i, x(i), y(i-1), i = 3, Number)
END PROGRAM  Smoothing

