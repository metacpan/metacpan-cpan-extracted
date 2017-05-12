PROGRAM  Decoding
   IMPLICIT  NONE
   CHARACTER(LEN=2)  :: SN_1, SN_2, SN_3*3
   CHARACTER(LEN=3)  :: Phone_1, Phone_2*4
   INTEGER           :: Amount
   INTEGER           :: Number
   INTEGER           :: Status
   LOGICAL           :: Problem
   CHARACTER(LEN=10) :: TitleFormat   = "(T8,A)"
   CHARACTER(LEN=10) :: HeadingFormat = "(T2,A)"
   CHARACTER(LEN=30) :: InputFormat   = "(A2,A2,A3,3X,A3,A4,3X,I5)"
   CHARACTER(LEN=30) :: OutputFormat  = "(1X, 5A, T14, 3A, T26,I6)"
   CHARACTER(LEN=30) :: LastLine      = "(1X, A, I3, A)"

   WRITE(*,TitleFormat)    "Sales Amount Table"
   WRITE(*,TitleFormat)    "=================="
   WRITE(*,*)
   WRITE(*,HeadingFormat)  "Sales No.   Phone No.   Amount"
   WRITE(*,HeadingFormat)  "---------   ---------   ------"
   Problem = .FALSE.
   Number = 0
   DO
      READ(*,InputFormat, IOSTAT=Status)  &
            SN_1, SN_2, SN_3, Phone_1, Phone_2, Amount
      IF (Status > 0) THEN
         WRITE(*,*)  "Something wrong in your input data"
         Problem = .TRUE.
         EXIT
      ELSE IF (Status < 0) THEN
         EXIT
      ELSE
         WRITE(*,OutputFormat)  &
               SN_1, "-", SN_2, "-", SN_3, Phone_1, "-", Phone_2, Amount
         Number = Number + 1
      END IF
   END DO
   IF (.NOT. Problem) THEN
      WRITE(*,*)
      WRITE(*,LastLine)  "Total", Number, " person(s) processed."
   END IF
END PROGRAM  Decoding
