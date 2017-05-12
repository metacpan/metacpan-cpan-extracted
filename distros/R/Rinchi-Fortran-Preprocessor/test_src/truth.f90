PROGRAM  Logical_Input
   IMPLICIT  NONE
   LOGICAL           :: P, Q
   INTEGER           :: i, Number

   WRITE(*,"(A, A)")  " ", "  Truth Table"
   WRITE(*,"(A, A)")  " ", "  -----------"
   WRITE(*,*)
   WRITE(*,"(A,A)")   " ", "    P      Q    P | Q  P & Q  P ^ Q  P = Q"
   WRITE(*,"(A,6A)")  " ", ("  -----", i = 1, 6)
   READ(*,"(I5)")  Number
   DO i = 1, Number
      READ(*,"(2L10)")  P, Q
      WRITE(*,"(A, 6L7)")  " ", P, Q, &
                            P .OR. Q, P .AND. Q, P .NEQV. Q, P .EQV. Q
   END DO
END PROGRAM  Logical_Input
