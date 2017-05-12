! ---------------------------------------------------------------
! This program computes all Armstrong numbers in the range of 
! 0 and 999.  An Armstrong number is a number such that the sum
! of its digits raised to the third power is equal to the number
! itself.  For example, 371 is an Armstrong number, since
! 3**3 + 7**3 + 1**3 = 371.
! ---------------------------------------------------------------

PROGRAM  ArmstrongNumber
   IMPLICIT  NONE

   INTEGER :: a, b, c                   ! the three digits
   INTEGER :: abc, a3b3c3               ! the number and its cubic sum
   INTEGER :: Count                     ! a counter

   Count = 0
   DO a = 0, 9                          ! for the left most digit
      DO b = 0, 9                       !   for the middle digit
         DO c = 0, 9                    !     for the right most digit
            abc    = a*100 + b*10 + c   !        the number
            a3b3c3 = a**3 + b**3 + c**3 !        the sum of cubes
            IF (abc == a3b3c3) THEN     !        if they are equal
               Count = Count + 1        !           count and display it
               WRITE(*,*)  'Armstrong number ', Count, ': ', abc
            END IF
         END DO
      END DO
   END DO

END PROGRAM  ArmstrongNumber
