PROGRAM  Decoding
   IMPLICIT  NONE
   INTEGER :: SalesNo, Phone, Amount
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
      READ(*,"(I10,I10,I5)", IOSTAT=Status)  SalesNo, Phone, Amount
      IF (Status > 0) THEN
         WRITE(*,*)  "Something wrong in your input data"
         Problem = .TRUE.
         EXIT
      ELSE IF (Status < 0) THEN
         EXIT
      ELSE
         SN_3 = MOD(SalesNo, 1000)
         SN_2 = MOD(SalesNo/1000,100)
         SN_1 = SalesNo/100000

         Phone_2 = MOD(Phone, 10000)
         Phone_1 = Phone / 10000
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
