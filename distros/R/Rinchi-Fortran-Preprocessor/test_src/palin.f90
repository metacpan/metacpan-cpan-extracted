! --------------------------------------------------------------------
! PROGRAM  Palindrome:
!    This program checks to see if an array is a palindrome.  An array
! is a palindrome if they read the same in both directions.
! --------------------------------------------------------------------

PROGRAM  Palindrome
   IMPLICIT  NONE

   INTEGER, PARAMETER :: LENGTH = 30    ! maximum array size
   INTEGER, DIMENSION(1:LENGTH) :: x    ! the array
   INTEGER            :: Size           ! actual array size (input)
   INTEGER            :: Head           ! pointer moving forward
   INTEGER            :: Tail           ! pointer moving backward
   INTEGER            :: i              ! running index

   READ(*,*) Size, (x(i), i = 1, Size)  ! read in the input array
   WRITE(*,*)  "Input array:"           ! display the input
   WRITE(*,*)  (x(i), i = 1, Size)

   Head = 1                             ! scan from the beginning
   Tail = Size                          ! scan from the end
   DO                                   ! checking array
      IF (Head >= Tail)  EXIT           !   exit if two pointers meet
      IF (x(Head) /= x(Tail))  EXIT     !   exit if two elements not equal
      Head = Head + 1                   !   equal.  Head moves forward
      Tail = Tail - 1                   !   and Tail moves backward
   END DO                               ! until done

   WRITE(*,*)
   IF (Head >= Tail) THEN               ! if Head cross Tail, then we have
      WRITE(*,*) "The input array is a palindrome"     ! a palindrome
   ELSE                                 ! otherwise, it is not a palindrome
      WRITE(*,*) "The input array is NOT a palindrome"
   END IF

END PROGRAM  Palindrome
