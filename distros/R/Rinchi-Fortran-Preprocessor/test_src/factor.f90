! ---------------------------------------------------------------
! This program determines all prime factors of an n integer >= 2.
! It first removes all factors of 2.  Then, removes all factors
! of 3, 5, 7, and so on.  All factors must be prime numbers since
! when a factor is tried all of whose non-prime factors have 
! already been removed.
! ---------------------------------------------------------------

PROGRAM  Factorize
   IMPLICIT  NONE

   INTEGER  :: Input
   INTEGER  :: Divisor
   INTEGER  :: Count

   WRITE(*,*)  'This program factorizes any integer >= 2 --> '
   READ(*,*)   Input

   Count = 0
   DO                         ! here, we try to remove all factors of 2
      IF (MOD(Input,2) /= 0 .OR. Input == 1)  EXIT
      Count = Count + 1       ! increase count
      WRITE(*,*)  'Factor # ', Count, ': ', 2
      Input = Input / 2       ! remove this factor from Input
   END DO

   Divisor = 3                ! now we only worry about odd factors
   DO                         ! 3, 5, 7, .... will be tried
      IF (Divisor > Input) EXIT    ! if a factor is too large, exit and done
      DO                      ! try this factor repeatedly
         IF (MOD(Input,Divisor) /= 0 .OR. Input == 1)  EXIT
         Count = Count + 1
         WRITE(*,*)  'Factor # ', Count, ': ', Divisor
         Input = Input / Divisor   ! remove this factor from Input
      END DO
      Divisor = Divisor + 2   ! move to next odd number
   END DO

END PROGRAM  Factorize
