! --------------------------------------------------------------------
! MODULE  MyTrigonometricFunctions:
!    This module provides the following functions and constants
!    (1) RadianToDegree()     - converts its argument in radian to
!                               degree
!    (2) DegreeToRadian()     - converts its argument in degree to
!                               radian
!    (3) MySIN()              - compute the sine of its argument in
!                               degree
!    (4) MyCOS()              - compute the cosine of its argument
!                               in degree
! --------------------------------------------------------------------

MODULE  MyTrigonometricFunctions
   IMPLICIT   NONE

   REAL, PARAMETER :: PI        = 3.1415926       ! some constants
   REAL, PARAMETER :: Degree180 = 180.0
   REAL, PARAMETER :: R_to_D    = Degree180/PI
   REAL, PARAMETER :: D_to_R    = PI/Degree180

CONTAINS

! --------------------------------------------------------------------
! FUNCTION  RadianToDegree():
!    This function takes a REAL argument in radian and converts it to
! the equivalent degree.
! --------------------------------------------------------------------

   REAL FUNCTION  RadianToDegree(Radian)
      IMPLICIT  NONE
      REAL, INTENT(IN) :: Radian

      RadianToDegree = Radian * R_to_D
   END FUNCTION  RadianToDegree

! --------------------------------------------------------------------
! FUNCTION  DegreeToRadian():
!    This function takes a REAL argument in degree and converts it to
! the equivalent radian.
! --------------------------------------------------------------------

   REAL FUNCTION  DegreeToRadian(Degree)
      IMPLICIT  NONE
      REAL, INTENT(IN) :: Degree

      DegreeToRadian = Degree * D_to_R
   END FUNCTION  DegreeToRadian

! --------------------------------------------------------------------
! FUNCTION  MySIN():
!    This function takes a REAL argument in degree and computes its
! sine value.  It does the computation by converting its argument to
! radian and uses Fortran's sin().
! --------------------------------------------------------------------

   REAL FUNCTION  MySIN(x)
      IMPLICIT  NONE
      REAL, INTENT(IN) :: x

      MySIN = SIN(DegreeToRadian(x))
   END FUNCTION  MySIN

! --------------------------------------------------------------------
! FUNCTION  MySIN():
!    This function takes a REAL argument in degree and computes its
! cosine value.  It does the computation by converting its argument to
! radian and uses Fortran's cos().
! --------------------------------------------------------------------

   REAL FUNCTION  MyCOS(x)
      IMPLICIT  NONE
      REAL, INTENT(IN) :: x

      MyCOS = COS(DegreeToRadian(x))
   END FUNCTION  MyCOS

END MODULE  MyTrigonometricFunctions
