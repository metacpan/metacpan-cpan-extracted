PROGRAM  SignControl
   IMPLICIT  NONE
   INTEGER   :: i
   REAL      :: x
   CHARACTER(LEN=*), PARAMETER :: Format  = "(1X,SS,I5,SP,I5,SS,F6.1,SP,F6.1)"
   CHARACTER(LEN=*), PARAMETER :: Heading = "   SS   SP    SS    SP"

   WRITE(*,"(1X,A)") Heading
   DO i = -5, 5
      x = REAL(i)
      WRITE(*,Format)  i, i, x, x
   END DO
END PROGRAM  SignControl
