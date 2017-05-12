! -------------------------------------------------------
! This program reads in three INTEGERs and displays them 
! in ascending order.
! -------------------------------------------------------
 
PROGRAM  Order
   IMPLICIT  NONE
 
   INTEGER  :: a, b, c

   READ(*,*)  a, b, c

   IF (a <= b .AND. a <= c) THEN   ! a the smallest
      IF (b <= c) THEN             !   a <= b <= c
         WRITE(*,*)  a, b, c
      ELSE                         !   a <= c <= b
         WRITE(*,*)  a, c, b
      END IF
   ELSE IF (b <= a .AND. b <= c) THEN  ! b the smallest
      IF (a <= c) THEN             !   b <= a <= c
         WRITE(*,*)  b, a, c
      ELSE                         !   b <= c <= a
         WRITE(*,*)  b, c, a
      END IF
   ELSE                            ! c the smallest
      IF (a <= b) THEN             !   c <= a <= b
         WRITE(*,*)  c, a, b
      ELSE                         !   c <= b <= a
         WRITE(*,*)  c, b, a
      END IF
   END IF

END PROGRAM  Order
