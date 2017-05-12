! ----------------------------------------------------------
! This program reads a series of input data values and 
! computes their arithmetic, geometric and harmonic means.
! Since geometric mean requires taking n-th root, all input
! data item must be all positive (a special requirement of
! this program , although it is not absolutely necessary).
! If an input item is not positive, it should be ignored.
! Since some data items may be ignored, this program also
! checks to see if no data items remain!
! ----------------------------------------------------------

PROGRAM   ComputingMeans
   IMPLICIT  NONE

   REAL    :: X
   REAL    :: Sum, Product, InverseSum
   REAL    :: Arithmetic, Geometric, Harmonic
   INTEGER :: Count, TotalNumber, TotalValid

   Sum        = 0.0                     ! for the sum
   Product    = 1.0                     ! for the product
   InverseSum = 0.0                     ! for the sum of 1/x
   TotalValid = 0                       ! # of valid items

   READ(*,*)  TotalNumber               ! read in # of items
   DO Count = 1, TotalNumber            ! for each item ...
      READ(*,*)  X                      ! read it in
      WRITE(*,*) 'Input item ', Count, ' --> ', X
      IF (X <= 0.0) THEN                ! if it is non-positive
         WRITE(*,*) 'Input <= 0.  Ignored'   ! ignore it
      ELSE                              ! otherwise,
         TotalValid = TotalValid + 1    ! count it in
         Sum        = Sum + X           ! compute the sum,
         Product    = Product * X       ! the product
         InverseSum = InverseSum + 1.0/X     ! and the sum of 1/x
      END IF
   END DO

   IF (TotalValid > 0) THEN             ! are there valid items?
      Arithmetic = Sum / TotalValid     ! yes, compute means
      Geometric  = Product**(1.0/TotalValid)
      Harmonic   = TotalValid / InverseSum

      WRITE(*,*)  'No. of valid items --> ', TotalValid
      WRITE(*,*)  'Arithmetic mean    --> ', Arithmetic
      WRITE(*,*)  'Geometric mean     --> ', Geometric
      WRITE(*,*)  'Harmonic mean      --> ', Harmonic
   ELSE                                 ! no, display a message
      WRITE(*,*)  'ERROR: none of the input is positive'
   END IF

END PROGRAM  ComputingMeans
