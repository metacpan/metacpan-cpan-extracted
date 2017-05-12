PROGRAM  Decoding
   IMPLICIT  NONE
   CHARACTER(LEN=2) :: SN_1, SN_2, SN_3*3
   CHARACTER(LEN=3) :: Phone_1, Phone_2*4
   CHARACTER(LEN=3) :: Filler_1, Filler_2
   INTEGER          :: Amount
   INTEGER          :: Number
   INTEGER          :: Status
   LOGICAL          :: Problem

   WRITE(*,"(A,A)")  " ", "      Sales Amount Table"
   WRITE(*,"(A,A)")  " ", "      =================="
   WRITE(*,*)
   WRITE(*,"(A, A)")  " ", "Sales No.   Phone No.   Amount"
   WRITE(*,"(A, A)")  " ", "---------   ---------   ------"
   Problem = .FALSE.
   Number = 0
   DO
      READ(*,"(7A,I5)", IOSTAT=Status)  SN_1, SN_2, SN_3, Filler_1,  &
                                        Phone_1, Phone_2, Filler_2, Amount
      IF (Status > 0) THEN
         WRITE(*,*)  "Something wrong in your input data"
         Problem = .TRUE.
         EXIT
      ELSE IF (Status < 0) THEN
         EXIT
      ELSE
         WRITE(*,"(10A,I10)")  &
            " ", SN_1, "-", SN_2, "-", SN_3, Filler_1, &
                 Phone_1, "-", Phone_2, Amount
         Number = Number + 1
      END IF
   END DO
   IF (.NOT. Problem) THEN
      WRITE(*,*)
      WRITE(*,"(A,A,I3,A)")  " ", "Total", Number, " person(s) processed."
   END IF
END PROGRAM  Decoding
