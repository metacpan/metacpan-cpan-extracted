! ---------------------------------------------------------------
! This program finds all prime numbers in the range of 2 and an
! input integer.
! ---------------------------------------------------------------

PROGRAM  Primes
   IMPLICIT  NONE
   
   INTEGER  :: Range, Number, Divisor, Count

   WRITE(*,*)  'What is the range ? '
   DO                                   ! keep trying to read a good input
      READ(*,*)  Range                  ! ask for an input integer
      IF (Range >= 2)  EXIT             ! if it is GOOD, exit
      WRITE(*,*)  'The range value must be >= 2.  Your input = ', Range
      WRITE(*,*)  'Please try again:'   ! otherwise, bug the user
   END DO
   
   Count = 1                            ! input is correct. start counting
   WRITE(*,*)                           ! since 2 is a prime
   WRITE(*,*)  'Prime number #', Count, ': ', 2
   DO Number = 3, Range, 2              ! try all odd numbers 3, 5, 7, ...

      Divisor = 3                       ! divisor starts with 3
      DO
         IF (Divisor*Divisor > Number .OR. MOD(Number,Divisor) == 0)  EXIT
         Divisor = Divisor + 2          ! if does not evenly divide, next odd
      END DO

      IF (Divisor*Divisor > Number) THEN     ! are all divisor exhausted?
         Count = Count + 1              ! yes, this Number is a prime
         WRITE(*,*)  'Prime number #', Count, ': ', Number
      END IF
   END DO
   
   WRITE(*,*)
   WRITE(*,*)  'There are ', Count, ' primes in the range of 2 and ', Range
   
END PROGRAM  Primes
      
