PROGRAM  Decoding
   IMPLICIT  NONE
   INTEGER :: Amount
   INTEGER :: SN_1, SN_2, SN_3
   INTEGER :: Phone_1, Phone_2
   INTEGER :: Number
   INTEGER :: Status
   LOGICAL :: Problem

   WRITE(*,"(A,A)")  " ", "      Sales Amount Table"
   WRITE(*,"(A,A)")  " ", "      =================="
   WRITE(*,*)
   WRITE(*,"(A, A)")  " ", "Sales No.   Phone No.   Amount"
   WRITE(*,"(A, A)")  " ", "---------   ---------   ------"
   Problem = .FALSE.
   Number = 0
   DO
      READ(*,"(2I2,I3,I6,I7,I5)", IOSTAT=Status)  &
         SN_1, SN_2, SN_3, Phone_1, Phone_2, Amount
      IF (Status > 0) THEN
         WRITE(*,*)  "Something wrong in your input data"
         Problem = .TRUE.
         EXIT
      ELSE IF (Status < 0) THEN
         EXIT
      ELSE
         WRITE(*,"(A,I2.2,A,I2.2,A,I3.3,I6.3,A,I4.4,I10)")  &
            " ", SN_1, "-", SN_2, "-", SN_3, Phone_1, "-", Phone_2, Amount
         Number = Number + 1
      END IF
   END DO
   IF (.NOT. Problem) THEN
      WRITE(*,*)
      WRITE(*,"(A,A,I3,A)")  " ", "Total", Number, " person(s) processed."
   END IF
END PROGRAM  Decoding
