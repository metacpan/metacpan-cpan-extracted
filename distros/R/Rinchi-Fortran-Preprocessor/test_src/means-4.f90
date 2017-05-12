! -----------------------------------------------------------
! This program can read an unknown number of input until the
! end of file is reached.  It calculates the arithmetic,
! geometric, and harmonic means of these numbers.
!
! This program uses IOSTAT= to detect the following two
! conditions:
!    (1)  if the input contains illegal symbols (not numbers)
!    (2)  if the end of input has reached
! -----------------------------------------------------------

PROGRAM   ComputingMeans
   IMPLICIT  NONE

   REAL    :: X
   REAL    :: Sum, Product, InverseSum
   REAL    :: Arithmetic, Geometric, Harmonic
   INTEGER :: Count, TotalValid
   INTEGER :: IO                        ! this is new variable

   Sum        = 0.0
   Product    = 1.0
   InverseSum = 0.0
   TotalValid = 0
   Count      = 0

   DO
      READ(*,*,IOSTAT=IO)  X            ! read in data
      IF (IO < 0)  EXIT                 ! IO < 0 means end-of-file reached
      Count = Count + 1                 ! otherwise, there are data in input
      IF (IO > 0) THEN                  ! IO > 0 means something wrong
         WRITE(*,*)  'ERROR: something wrong in your input'
         WRITE(*,*)  'Try again please'
      ELSE                              ! IO = 0 means everything is normal
         WRITE(*,*) 'Input item ', Count, ' --> ', X
         IF (X <= 0.0) THEN
            WRITE(*,*) 'Input <= 0.  Ignored'
         ELSE
            TotalValid = TotalValid + 1
            Sum        = Sum + X
            Product    = Product * X
            InverseSum = InverseSum + 1.0/X
         END IF
      END IF
   END DO

   WRITE(*,*)
   IF (TotalValid > 0) THEN
      Arithmetic = Sum / TotalValid
      Geometric  = Product**(1.0/TotalValid)
      Harmonic   = TotalValid / InverseSum

      WRITE(*,*)  '# of items read --> ', Count
      WRITE(*,*)  '# of valid items -> ', TotalValid
      WRITE(*,*)  'Arithmetic mean --> ', Arithmetic
      WRITE(*,*)  'Geometric mean  --> ', Geometric
      WRITE(*,*)  'Harmonic mean   --> ', Harmonic
   ELSE
      WRITE(*,*)  'ERROR: none of the input is positive'
   END IF

END PROGRAM  ComputingMeans
