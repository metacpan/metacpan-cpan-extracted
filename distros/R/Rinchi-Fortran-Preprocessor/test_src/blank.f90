PROGRAM  BlankTest
   IMPLICIT  NONE
   INTEGER           :: a, b
   REAL              :: x, y
   INTEGER           :: IO
   CHARACTER(LEN=60) :: Format
   CHARACTER(LEN=5)  :: Input

   Format = "(A5, BN, T1, I5, BZ, T1, I5, BN, T1, F5.2, BZ, T1, F5.2)"

   WRITE(*,"(1X,A)")  "Input    BN    BZ      BN      BZ"
   WRITE(*,"(1X,A)")  "-----   ---   ---   -----   -----"
   DO
      READ(*,Format, IOSTAT=IO)    Input, a, b, x, y
      IF (IO < 0) EXIT
      WRITE(*,"(1X, A, 2I6, 2F8.2)")  Input, a, b, x, y
   END DO
END PROGRAM  BlankTest
