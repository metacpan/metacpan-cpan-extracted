PROGRAM  Smoothing
   IMPLICIT  NONE
   INTEGER, PARAMETER           :: MAX_SIZE = 20
   REAL, DIMENSION(1:MAX_SIZE)  :: x, y
   INTEGER                      :: Number
   INTEGER                      :: i

   READ(*,"(I5)")  Number
   READ(*,"(5F10.0)")  (x(i), i=1, Number)
   DO i = 1, Number-1
      y(i) = (x(i) + x(i+1)) / 2.0
   END DO
   WRITE(*,"(A)")   "             **************************"
   WRITE(*,"(A)")   "             *  Data Smoothing Table  *"
   WRITE(*,"(A)")   "             **************************"
   WRITE(*,*)
   WRITE(*,"(4A)")  (" ", " No       x         y    ", i = 1, 2)
   WRITE(*,"(4A)")  (" ", "---  --------  --------  ", i = 1, 2)
   WRITE(*,"(I4,F10.2,A10,I6,2F10.2)")  1, x(1), "NA", 2, x(2), y(1)
   WRITE(*,"(I4,2F10.2,I6,2F10.2)")     (i, x(i), y(i-1), i = 3, Number)
END PROGRAM  Smoothing


