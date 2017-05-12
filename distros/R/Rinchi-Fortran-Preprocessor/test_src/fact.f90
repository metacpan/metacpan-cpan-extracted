! ----------------------------------------------------------
! Given a non-negative integer N, this program computes
! the factorial of N.  The factorial of N, N!, is defined as
!         N! = 1 x 2 x 3 x .... x (N-1) x N
! and 0! = 1.
! ----------------------------------------------------------

PROGRAM  Factorial
   IMPLICIT  NONE

   INTEGER :: N, i, Answer

   WRITE(*,*)  'This program computes the factorial of'
   WRITE(*,*)  'a non-negative integer'
   WRITE(*,*)
   WRITE(*,*)  'What is N in N! --> '
   READ(*,*)   N
   WRITE(*,*)

   IF (N < 0) THEN                 ! input error if N < 0
      WRITE(*,*)  'ERROR: N must be non-negative'
      WRITE(*,*)  'Your input N = ', N
   ELSE IF (N == 0) THEN           ! 0! = 1
      WRITE(*,*)  '0! = 1'
   ELSE                            ! N > 0 here
      Answer = 1                   ! initially N! = 1
      DO i = 1, N                  ! for each i = 1, 2, ..., N
         Answer = Answer * i       ! multiply i to Answer
      END DO
      WRITE(*,*)  N, '! = ', Answer
   END IF

END PROGRAM  Factorial
