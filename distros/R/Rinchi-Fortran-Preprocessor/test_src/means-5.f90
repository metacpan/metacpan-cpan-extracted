! ----------------------------------------------------------
!    This program contains three functions for computing the
! arithmetic, geometric and harmonic means of three REALs.
! ----------------------------------------------------------

PROGRAM  ComputingMeans
   IMPLICIT  NONE

   REAL  :: a, b, c

   READ(*,*)  a, b, c
   WRITE(*,*) 'Input: ', a, b, c
   WRITE(*,*)
   WRITE(*,*) 'Arithmetic mean = ', ArithMean(a, b, c)
   WRITE(*,*) 'Geometric mean  = ', GeoMean(a, b, c)
   WRITE(*,*) 'Harmonic mean   = ', HarmonMean(a, b, c)

CONTAINS

! ----------------------------------------------------------
! REAL FUNCTION  ArithMean() :
!    This function computes the arithmetic mean of its
! three REAL arguments.
! ----------------------------------------------------------

   REAL FUNCTION  ArithMean(a, b, c)
      IMPLICIT  NONE

      REAL, INTENT(IN) :: a, b, c

      ArithMean = (a + b + c) /3.0
   END FUNCTION  ArithMean

! ----------------------------------------------------------
! REAL FUNCTION  GeoMean() :
!    This function computes the geometric mean of its
! three REAL arguments.
! ----------------------------------------------------------

   REAL FUNCTION  GeoMean(a, b, c)
      IMPLICIT  NONE

      REAL, INTENT(IN) :: a, b, c

      GeoMean = (a * b * c)**(1.0/3.0)
   END FUNCTION  GeoMean

! ----------------------------------------------------------
! REAL FUNCTION  HarmonMean() :
!    This function computes the harmonic mean of its
! three REAL arguments.
! ----------------------------------------------------------

   REAL FUNCTION  HarmonMean(a, b, c)
      IMPLICIT  NONE

      REAL, INTENT(IN) :: a, b, c

      HarmonMean = 3.0 / (1.0/a + 1.0/b + 1.0/c)
   END FUNCTION  HarmonMean

END PROGRAM  ComputingMeans
