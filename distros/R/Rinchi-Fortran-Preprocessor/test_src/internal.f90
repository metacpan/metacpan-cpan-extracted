PROGRAM  Test
   IMPLICIT NONE
   CHARACTER(LEN=40)         :: Buffer
   INTEGER, DIMENSION(1:100) :: X
   INTEGER :: i

   WRITE(Buffer,"(10I4)") (i, i = 1, 10)
   WRITE(*,*)  Buffer
   WRITE(*,*)
   READ(Buffer,"(BN,8I5)")   (X(i), i = 1, 8)
   WRITE(*,*)                (X(i), i = 1, 8)
   WRITE(*,*)
   READ(Buffer,"(BZ,8I5)")   (X(i), i = 1, 8)
   WRITE(*,*)                (X(i), i = 1, 8)
END PROGRAM Test
