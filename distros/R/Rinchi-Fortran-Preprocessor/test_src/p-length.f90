! -----------------------------------------------------------
!   Calculate the length of a parabola given height and base.                                         *
! -----------------------------------------------------------

PROGRAM  ParabolaLength
   IMPLICIT  NONE

   REAL  :: Height, Base, Length
   REAL  :: temp, t

   WRITE(*,*)  'Height of a parabola : '
   READ(*,*)   Height

   WRITE(*,*)  'Base of a parabola   : '
   READ(*,*)   Base

! ... temp and t are two temporary variables

   t      = 2.0 * Height
   temp   = SQRT(t**2 + Base**2)
   Length = temp + Base**2/t*LOG((t + temp)/Base)

   WRITE(*,*)
   WRITE(*,*)  'Height = ', Height
   WRITE(*,*)  'Base   = ', Base
   WRITE(*,*)  'Length = ', Length

END PROGRAM  ParabolaLength
