! ----------------------------------------------------------
! This program computes the average of each student and the
! the average of the class.  The input file starts with an
! integer giving the number of classes.  For each class, the
! input starts with an integer giving the number of students
! of that class, followed that number of lines on each of 
! which there are three scores.  This program reads in the
! scores and computes their average and also the class 
! averages of each score and the grant average of the class.
! ----------------------------------------------------------

PROGRAM  ClassAverage
   IMPLICIT  NONE

   INTEGER :: NoClass              ! the no. of classes
   INTEGER :: NoStudent            ! the no. of students in each class
   INTEGER :: Class, Student       ! DO control variables
   REAL    :: Score1, Score2, Score3, Average
   REAL    :: Average1, Average2, Average3, GrantAverage

   READ(*,*)  NoClass              ! read in the # of classes
   DO Class = 1, NoClass           ! for each class, do the following
      READ(*,*)  NoStudent         !   the # of student in this class
      WRITE(*,*)
      WRITE(*,*) 'Class ', Class, ' has ', NoStudent, ' students'
      WRITE(*,*)
      Average1 = 0.0               !   initialize average variables
      Average2 = 0.0
      Average3 = 0.0
      DO Student = 1, NoStudent    !   for each student in this class
         READ(*,*)  Score1, Score2, Score3   ! read in his/her scores
         Average1 = Average1 + Score1        ! prepare for class average
         Average2 = Average2 + Score2
         Average3 = Average3 + Score3
         Average  = (Score1 + Score2 + Score3) / 3.0   ! average of this one
         WRITE(*,*)  Student, Score1, Score2, Score3, Average
      END DO
      WRITE(*,*)  '----------------------'
      Average1     = Average1 / NoStudent    ! class average of score1
      Average2     = Average2 / NoStudent    ! class average of score2
      Average3     = Average3 / NoStudent    ! class average of score3
      GrantAverage = (Average1 + Average2 + Average3) / 3.0
      WRITE(*,*) 'Class Average: ', Average1, Average2, Average3
      WRITE(*,*) 'Grant Average: ', GrantAverage
   END DO

END PROGRAM  ClassAverage
