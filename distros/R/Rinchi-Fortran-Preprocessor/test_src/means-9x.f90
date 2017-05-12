! --------------------------------------------------------------------
! PROGRAM  Grading:
!    This program reads in a set of values, computes its mean,
! variance, and standard deviation, and use the mean and standard
! deviation to compute a letter grade.
!    This program shows you passing arrays as arguments with assumed-
! shape arguments.  Since all lower bounds are 1, no extent 
! information are passed. 
! --------------------------------------------------------------------

PROGRAM  Grading
   IMPLICIT  NONE

   INTEGER, PARAMETER :: MAX_SIZE = 100
   REAL, DIMENSION(1:MAX_SIZE) :: InputData
   INTEGER                     :: ActualSize

   CALL  ReadArray(InputData, ActualSize)
   CALL  DisplayResult(InputData, ActualSize)

CONTAINS

! --------------------------------------------------------------------
! SUBROUTINE  ReadArray():
!    This subroutine reads in the number of data and the data set.
! --------------------------------------------------------------------

   SUBROUTINE ReadArray(x, n)
      IMPLICIT  NONE
      INTEGER, INTENT(OUT)             :: n
      REAL, DIMENSION(1:), INTENT(OUT) :: x
      INTEGER                          :: i

      READ(*,*)  n
      READ(*,*)  (x(i), i = 1, n)
   END SUBROUTINE  ReadArray

! --------------------------------------------------------------------
! SUBROUTINE  DisplayResult():
!    This subroutine calls MeanVariance() to compute the mean,
! variance and standard deviation, and prints a grade report.  The
! letter grade is determined by CHARACTER function LetterGrade().
! --------------------------------------------------------------------

   SUBROUTINE  DisplayResult(Data, n)
      IMPLICIT  NONE
      INTEGER, INTENT(IN)             :: n
      REAL, DIMENSION(1:), INTENT(IN) :: Data
      INTEGER                         :: i
      REAL                            :: Mean, Var, Std

      CALL  MeanVariance(Data, n, Mean, Var, Std)
      WRITE(*,*)  "Grading Report"
      WRITE(*,*)
      DO i = 1, n
         WRITE(*,*) Data(i), "  ", LetterGrade(Data(i), Mean, Std)
      END DO
      WRITE(*,*)
      WRITE(*,*)  "No. of students          = ", n
      WRITE(*,*)  "Class average            = ", Mean
      WRITE(*,*)  "Class variance           = ", Var
      WRITE(*,*)  "Class standard deviation = ", Std
   END SUBROUTINE  DisplayResult

! --------------------------------------------------------------------
! CHARACTER FUNCTION  LetterGrade():
!    This function receives a score and the mean and standard deviation
! values, and returns a letter grade.
! --------------------------------------------------------------------

   CHARACTER FUNCTION  LetterGrade(x, Mean, StdDev)
      IMPLICIT  NONE
      REAL, INTENT(IN) :: x, Mean, StdDev

      IF (x < Mean - 1.5*StdDev) THEN
         LetterGrade = "F"
      ELSE IF (x < Mean - 0.5*StdDev) THEN
         LetterGrade = "D"
      ELSE IF (x < Mean + 0.5*StdDev) THEN
         LetterGrade = "C"
      ELSE IF (x < 1.5*StdDev) THEN
         LetterGrade = "B"
      ELSE
         LetterGrade = "A"
      END IF
   END FUNCTION  LetterGrade

! --------------------------------------------------------------------
! SUBROUTINE  MeanVariance():
!    This subroutine computes the mean, variance and standard
! deviation.
! --------------------------------------------------------------------

   SUBROUTINE  MeanVariance(Data, n, Mean, Variance, StdDev)
      IMPLICIT  NONE
      INTEGER, INTENT(IN)             :: n
      REAL, DIMENSION(1:), INTENT(IN) :: Data
      REAL, INTENT(OUT)               :: Mean, Variance, StdDev
      INTEGER                         :: i

      Mean = 0.0
      DO i = 1, n
         Mean = Mean + Data(i)
      END DO
      Mean = Mean / n

      Variance = 0.0
      DO i = 1, n
         Variance = Variance + (Data(i) - Mean)**2
      END DO
      Variance = Variance / n
      StdDev   = SQRT(Variance)
   END SUBROUTINE  MeanVariance

END PROGRAM  Grading
