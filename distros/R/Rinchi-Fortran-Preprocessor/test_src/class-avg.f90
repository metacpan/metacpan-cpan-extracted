PROGRAM  Input_1
   IMPLICIT  NONE
   CHARACTER(LEN=25) :: Name, ClassAverage
   CHARACTER(LEN=30) :: FormatIn, FormatOut, FormatAvg
   INTEGER           :: Number, i
   INTEGER           :: Score1, Score2, Score3
   REAL              :: Average
   REAL              :: Score1Avg, Score2Avg, Score3Avg, ClassAvg

   FormatIn  = "(A25, 3I5)"
   FormatOut = "(A, A25, 3I8, F9.2)"
   FormatAvg = "(A, A25, 3F8.2, F9.2)"
   WRITE(*,"(2A)")  " ", "Name                       Score1  Score2  Score3  Average"
   WRITE(*,"(2A)")  " ", "=========================  ======  ======  ======  ======="
   ClassAverage = "Average"
   Score1Avg    = 0.0
   Score2Avg    = 0.0
   Score3Avg    = 0.0
   READ(*,*)  Number
   DO i = 1, Number
      READ(*,FormatIn)  Name, Score1, Score2, Score3
      Average = REAL(Score1 + Score2 + Score3) / 3.0
      WRITE(*,FormatOut)  " ", Name, Score1, Score2, Score3, Average
      Score1Avg = Score1Avg + Score1
      Score2Avg = Score2Avg + Score2
      Score3Avg = Score3Avg + Score3
   END DO
   Score1Avg = Score1Avg / Number
   Score2Avg = Score2Avg / Number
   Score3Avg = Score3Avg / Number
   ClassAvg  = (Score1Avg + Score2Avg + Score3Avg) / 3.0
   WRITE(*,"(2A)")     " ", "=========================  ======  ======  ======  ======="
   WRITE(*,FormatAvg)  " ", ClassAverage, Score1Avg, Score2Avg, Score3Avg, ClassAvg
END PROGRAM  Input_1
