! ---------------------------------------------------------------
! PROGRAM  Reverse:
!    This program reverses the order of an input array.
! ---------------------------------------------------------------

PROGRAM  Reverse
   IMPLICIT  NONE

   INTEGER, PARAMETER :: SIZE = 30      ! maximum array size
   INTEGER, DIMENSION(1:SIZE) :: a      ! input array
   INTEGER            :: n              ! actual input array size
   INTEGER            :: Head           ! pointer moving forward
   INTEGER            :: Tail           ! pointer moving backward
   INTEGER            :: Temp, i

   READ(*,*)  n                         ! read in the input array
   READ(*,*)  (a(i), i = 1, n)
   WRITE(*,*) "Input array:"            ! display the input array
   WRITE(*,*) (a(i), i = 1, n)

   Head = 1                             ! start with the beginning
   Tail = n                             ! start with the end
   DO                                   ! for each pair...
      IF (Head >= Tail)  EXIT           !    if Head crosses Tail, exit
      Temp    = a(Head)                 !    otherwise, swap them
      a(Head) = a(Tail)
      a(Tail) = Temp
      Head    = Head + 1                !    move forward
      Tail    = Tail - 1                !    move backward
   END DO                               ! loop back

   WRITE(*,*)                           ! display the result
   WRITE(*,*)  "Reversed array:"
   WRITE(*,*)  (a(i), i = 1, n)

END PROGRAM  Reverse

