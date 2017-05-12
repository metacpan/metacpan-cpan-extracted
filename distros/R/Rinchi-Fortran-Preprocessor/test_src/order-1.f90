! -------------------------------------------------------
! This program reads in three INTEGERs and displays them 
! in ascending order.
! -------------------------------------------------------
 
PROGRAM  Order
   IMPLICIT  NONE
 
   INTEGER  :: a, b, c

   READ(*,*)  a, b, c

   IF (a < b) THEN                 ! a < b here
      IF (a < c) THEN              !   a < c     : a the smallest
         IF (b < c) THEN           !      b < c  : a < b < c
            WRITE(*,*)  a, b, c
         ELSE                      !      c <= b : a < c <= b
            WRITE(*,*)  a, c, b
         END IF
      ELSE                         !   a >= c    : c <= a < b
         WRITE(*,*) c, a, b
      END IF
   ELSE                            ! b <= a here
      IF (b < c) THEN              !   b < c     : b the smallest
         IF (a < c) THEN           !     a < c   : b <= a < c 
            WRITE(*,*)  b, a, c
         ELSE                      !     a >= c  : b < c <= a
            WRITE(*,*)  b, c, a
         END IF
      ELSE                         !   c <= b    : c <= b <= a
         WRITE(*,*)  c, b, a
      END IF
   END IF

END PROGRAM  Order
