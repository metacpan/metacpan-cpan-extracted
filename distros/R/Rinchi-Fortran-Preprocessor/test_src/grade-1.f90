! ----------------------------------------------------------
! This program reads three marks, computes their average
! and determines the corresponding letter grade with
! the following table:
!
!         A   : average >= 90
!         AB  : 85 <= average < 90
!         B   : 80 <= average < 84
!         BC  : 75 <= average < 79
!         C   : 70 <= average < 74
!         CD  : 65 <= average < 69
!         D   : 60 <= average < 64
!         F   : average < 60
!
! where 'average' is the rounded average of the three 
! marks.  More precisely, if the average is 78.6, then it
! becomes 79 after rounding; or, if the average is 78.4,
! it becomes 78 after truncating.
! ----------------------------------------------------------

PROGRAM  LetterGrade
   IMPLICIT   NONE

   REAL              :: Mark1, Mark2, Mark3
   REAL              :: Average
   CHARACTER(LEN=2)  :: Grade

   READ(*,*)  Mark1, Mark2, Mark3
   Average = (Mark1 + Mark2 + Mark3) / 3.0

   SELECT CASE (NINT(Average))     ! round Average before use
      CASE (:59)                   ! <= 59 -------------> F
         Grade = 'F '
      CASE (60:64)                 ! >= 60 and <= 64 ---> D
         Grade = 'D '
      CASE (65:69)                 ! >= 65 and <= 69 ---> CD
         Grade = 'CD'
      CASE (70:74)                 ! >= 70 and <= 74 ---> C
         Grade = 'C '
      CASE (75:79)                 ! >= 75 and <= 79 ---> BC
         Grade = 'BC'
      CASE (80:84)                 ! >= 80 and <= 84 ---> B
         Grade = 'B '
      CASE (85:89)                 ! >= 84 and <= 89 ---> AB
         Grade = 'AB'
      CASE DEFAULT                 ! >= 90 -------------> A
         Grade = 'A '
   END SELECT

   WRITE(*,*)  'First Mark    : ', Mark1
   WRITE(*,*)  'Second Mark   : ', Mark2
   WRITE(*,*)  'Third Mark    : ', Mark3
   WRITE(*,*)  'Average       : ', Average
   WRITE(*,*)  'Letter Grade  : ', Grade

END PROGRAM  LetterGrade
