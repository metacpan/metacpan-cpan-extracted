! --------------------------------------------------------------------
! This program finds all prime numbers in the range of 2 and an
! input integer.
! --------------------------------------------------------------------

PROGRAM  Primes
   IMPLICIT  NONE
   
   INTEGER  :: Range, Number, Count

   Range = GetNumber()   
   Count = 1                            ! input is correct. start counting
   WRITE(*,*)                           ! since 2 is a prime
   WRITE(*,*)  'Prime number #', Count, ': ', 2
   DO Number = 3, Range, 2              ! try all odd numbers 3, 5, 7, ...
      IF (Prime(Number)) THEN
         Count = Count + 1              ! yes, this Number is a prime
         WRITE(*,*)  'Prime number #', Count, ': ', Number
      END IF
   END DO
   
   WRITE(*,*)
   WRITE(*,*)  'There are ', Count, ' primes in the range of 2 and ', Range

CONTAINS

! --------------------------------------------------------------------
! INTEGER FUNCTION  GetNumber()
!    This function does not require any formal argument.  It keeps
! asking the reader for an integer until the input value is greater
! than or equal to 2.
! --------------------------------------------------------------------

   INTEGER FUNCTION  GetNumber()
      IMPLICIT  NONE

      INTEGER :: Input

      WRITE(*,*)  'What is the range ? '
      DO                                ! keep trying to read a good input
         READ(*,*)  Input               ! ask for an input integer
         IF (Input >= 2)  EXIT          ! if it is GOOD, exit
         WRITE(*,*)  'The range value must be >= 2.  Your input = ', Input
         WRITE(*,*)  'Please try again:'     ! otherwise, bug the user
      END DO
      GetNumber = Input
   END FUNCTION  GetNumber
      
! --------------------------------------------------------------------
! LOGICAL FUNCTION  Prime()
!    This function receives an INTEGER formal argument Number.  If it
! is a prime number, .TRUE. is returned; otherwise, this function
! returns .FALSE.
! --------------------------------------------------------------------

   LOGICAL FUNCTION  Prime(Number)
      IMPLICIT  NONE

      INTEGER, INTENT(IN) :: Number 
      INTEGER             :: Divisor
   
      IF (Number < 2) THEN
         Prime = .FALSE.
      ELSE IF (Number == 2) THEN
         Prime = .TRUE.
      ELSE IF (MOD(Number,2) == 0) THEN
         Prime = .FALSE.
      ELSE
         Divisor = 3
         DO
            IF (Divisor*Divisor>Number .OR. MOD(Number,Divisor)==0)  EXIT
            Divisor = Divisor + 2
         END DO
         Prime = Divisor*Divisor > Number
      END IF
   END FUNCTION  Prime

END PROGRAM  Primes
