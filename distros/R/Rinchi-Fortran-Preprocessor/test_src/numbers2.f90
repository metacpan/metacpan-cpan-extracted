PROGRAM  Select_Numbers
   IMPLICIT  NONE
   INTEGER           :: Number, i
   REAL              :: u, v, Sum
   CHARACTER(LEN=40) :: ReadIn, WriteOut, Title, Last

   Title    = "(1X,A)"
   ReadIn   = "(T11, F10.2, T41, F10.2)"
   WriteOut = "(1X, I4, A, 2F7.2)"
   Last     = "(1X, A, F7.2)"

   READ(*,"(I5)")  Number
   Sum = 0.0
   WRITE(*,Title)  "Input Number List"
   WRITE(*,Title)  "================="
   WRITE(*,*)
   DO i = 1, Number
      READ(*,ReadIn)  u, v
      WRITE(*,WriteOut)  i, " - ", u, v
      Sum = Sum + u*v
   END DO
   WRITE(*,Title)  "---------------------"
   WRITE(*,Last)   "Sum = ", Sum
END PROGRAM  Select_Numbers
