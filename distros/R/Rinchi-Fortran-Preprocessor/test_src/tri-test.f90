! -----------------------------------------------------------------------
! PROGRAM  TrigonFunctTest:
!    This program tests the functions in module MyTrigonometricFunctions.
! Module MyTrigonometricFunctions is stored in file trigon.f90.
! Functions in that module use degree rather than radian.  This program
! displays the sin(x) and cos(x) values for x=-180, -170, ..., 0, 10, 20,
! 30, ..., 160, 170 and 180.  Note that the sin() and cos() function
! in module MyTrigonometricFunctions are named MySIN(x) and MyCOS(x).
! -----------------------------------------------------------------------

PROGRAM  TrigonFunctTest
   USE  MyTrigonometricFunctions        ! use a module

   IMPLICIT  NONE

   REAL :: Begin = -180.0               ! initial value
   REAL :: Final =  180.0               ! final value
   REAL :: Step  =   10.0               ! step size
   REAL :: x

   WRITE(*,*)  'Value of PI = ', PI
   WRITE(*,*)
   x = Begin                            ! start with 180 degree
   DO
      IF (x > Final)  EXIT              ! if x > 180 degree, EXIT
      WRITE(*,*)  'x = ',  x, 'deg   sin(x) = ', MySIN(x), &
                  '   cos(x) = ', MyCOS(x)
      x = x + Step                      ! advance x
   END DO

END PROGRAM  TrigonFunctTest
   