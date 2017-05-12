! -------------------------------------------------------------
! Two examination papers are written at the end of the course.
! The final mark is either the average of the two papers, or
! the average of the two papers and the class record mark (all
! weighted equally), whichever is the higher.  The program 
! should reads in the class record mark and the marks of the
! papers, computes the average, and shows PASS (>= 50%) or
! FAIL (< 50%).
! -------------------------------------------------------------

PROGRAM  FinalMark
   IMPLICIT  NONE

   REAL    :: Mark1, Mark2         ! the marks of the papers
   REAL    :: Final                ! the final marks
   REAL    :: ClassRecordMark      ! the class record mark
   
   REAL, PARAMETER :: PassLevel = 50.0  ! the pass level

   READ(*,*)  ClassRecordMark, Mark1, Mark2
   
   Final = (Mark1 + Mark2) / 2.0
   IF (Final <= ClassRecordMark) THEN
      Final = (Mark1 + Mark2 + ClassRecordMark) / 3.0
   END IF

   WRITE(*,*)  'Class Record Mark : ', ClassRecordMark
   WRITE(*,*)  'Mark 1            : ', Mark1
   WRITE(*,*)  'Mark 2            : ', Mark2
   WRITE(*,*)  'Final Mark        : ', Final

   IF (Final >= PassLevel) THEN
      WRITE(*,*)  'Pass Status       : PASS'
   ELSE
      WRITE(*,*)  'Pass Status       : FAIL'
   END IF

END PROGRAM  FinalMark
