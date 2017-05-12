PROGRAM  CheckBook
   IMPLICIT   NONE
   CHARACTER(LEN=1)  :: Code
   CHARACTER(LEN=15) :: Line
   INTEGER           :: Payment, Deposit, Balance, Input
   INTEGER           :: Count
   INTEGER           :: Status
   CHARACTER(LEN=*), PARAMETER :: Filler      = "   *******"
   CHARACTER(LEN=*), PARAMETER :: DashLine    = "-----------------------------------"
   CHARACTER(LEN=*), PARAMETER :: TitleFormat = "(1X, A/1X, A//1X, A/1X, A)"
   CHARACTER(LEN=*), PARAMETER :: InputLine   = "(A)"
   CHARACTER(LEN=*), PARAMETER :: CheckLine   = "(1X, A/ 1X, I5, SP, 3I10/1X, A)"
   CHARACTER(LEN=*), PARAMETER :: PaymentLine = "(1X, I5, SP, I10, A, I10)"
   CHARACTER(LEN=*), PARAMETER :: DepositLine = "(1X, I5, A, SP, 2I10)"
   CHARACTER(LEN=*), PARAMETER :: LastLine    = "(1X, A/ 1X, A, SP, 3I10)"

   WRITE(*,TitleFormat)  "Check Book Reference Listing",        &
                         "============================",        &
                         "Count   Payment   Deposit   Balance", &
                         "-----   -------   -------   -------"

   Payment = 0
   Deposit = 0
   Balance = 0
   Count   = 0
   DO
      READ(*,InputLine,IOSTAT=Status)  Line
      IF (Status < 0)  EXIT
      Code  = Line(1:1)
      Count = Count + 1
      SELECT CASE (Code)
         CASE("C", "c")
            WRITE(*,CheckLine)  DashLine, Count, Payment, Deposit, Balance, DashLine
         CASE("P", "p")
            READ(Line,"(T11,I5)")  Input
            Payment = Payment + Input
            Balance = Balance - Input
            WRITE(*,PaymentLine)  Count, Input, Filler, Balance
         CASE("D", "d")
            READ(Line,"(T6,I5)")   Input
            Deposit = Deposit + Input
            Balance = Balance + Input
            WRITE(*,DepositLine)  Count, Filler, Input, Balance
      END SELECT
   END DO

   WRITE(*,LastLine)  DashLine, "Total", Payment, Deposit, Balance
END PROGRAM  CheckBook
