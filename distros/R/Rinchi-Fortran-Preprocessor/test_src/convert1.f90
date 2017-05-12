! ---------------------------------------------------------------
!    This program "contains" two REAL functions:
!         (1)  Cm_to_Inch() takes a real inch unit and converts
!              it to cm unit, and
!         (2)  Inch_to_cm() takes a real cm unit and converts it
!              to inch unit.
! The main program uses these functions to convert 0, 0.5, 1, 1.5,
! 2.0, 2.5, ..., 8.0, 8.5, 9.0, 9.5 and 10.0 inch (resp., cm) to
! cm (resp., inch).
! ---------------------------------------------------------------

PROGRAM  Conversion
   IMPLICIT  NONE

   INTERFACE
      REAL FUNCTION  Cm_to_Inch(cm)
         REAL, INTENT(IN) :: cm
      END FUNCTION  Cm_to_Inch

      REAL FUNCTION  Inch_to_Cm(inch)
         REAL, INTENT(IN) :: inch
      END FUNCTION  Inch_to_Cm
   END INTERFACE

   REAL, PARAMETER :: Initial = 0.0, Final = 10.0, Step = 0.5
   REAL            :: x

   x = Initial
   DO                         ! x = 0, 0.5, 1.0, ..., 9.0, 9.5, 10
      IF (x > Final)  EXIT
      WRITE(*,*)  x, 'cm = ',   Cm_to_Inch(x), 'inch and ',  &
                  x, 'inch = ', Inch_to_Cm(x), 'cm'
      x = x + Step
   END DO

END PROGRAM  Conversion

! ---------------------------------------------------------------
! REAL FUNCTION  Cm_to_Inch()
!    This function converts its real input in cm to inch.
! ---------------------------------------------------------------

REAL FUNCTION  Cm_to_Inch(cm)
   IMPLICIT  NONE

   REAL, INTENT(IN) :: cm
   REAL, PARAMETER  :: To_Inch = 0.3937   ! conversion factor

   Cm_to_Inch = To_Inch * cm
END FUNCTION  Cm_to_Inch

! ---------------------------------------------------------------
! REAL FUNCTION  Inch_to_Cm()
!    This function converts its real input in inch to cm.
! ---------------------------------------------------------------

REAL FUNCTION  Inch_to_Cm(inch)
   IMPLICIT  NONE

   REAL, INTENT(IN) :: inch
   REAL, PARAMETER  :: To_Cm = 2.54       ! conversion factor

   Inch_to_Cm = To_Cm * inch
END FUNCTION  Inch_to_Cm
