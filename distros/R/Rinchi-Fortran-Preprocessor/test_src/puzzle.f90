! ----------------------------------------------------------
! This program solve the following puzzle:
!                RED
!            x   FOR
!            -------
!             DANGER
! where each distinct letter represents a different digit.
! Moreover, R, F and D cannot be zero.
! ----------------------------------------------------------

PROGRAM  Puzzle
   IMPLICIT  NONE

   INTEGER :: R, E, D, F, O, A, N, G    ! the digits
   INTEGER :: RED, FOR, DANGER          ! the constructed values
   INTEGER :: Count                     ! solutions count

   WRITE(*,*)  'This program solves the following puzzle:'
   WRITE(*,*)
   WRITE(*,*)  '    RED'
   WRITE(*,*)  'x   FOR'
   WRITE(*,*)  '-------'
   WRITE(*,*)  ' DANGER'
   WRITE(*,*)

   Count = 0
   DO R = 1, 9
     DO E = 0, 9
       IF (E == R) CYCLE
       DO D = 1, 9
         IF (D == R .OR. D == E) CYCLE
         DO F = 1, 9
           IF (F == R .OR. F == E .OR. F == D) CYCLE
           DO O = 0, 9
             IF (O == R .OR. O == E .OR. O == D .OR.            &
                 O == F)  CYCLE
             DO A = 0, 9
               IF (A == R .OR. A == E .OR. A == D .OR.          &
                   A == F .OR. A == O)  CYCLE
               DO N = 0, 9
                 IF (N == R .OR. N == E .OR. N == D .OR.        &
                     N == F .OR. N == O .OR. N == A)  CYCLE
                 DO G = 0, 9
                   IF (G == R .OR. G == E .OR. G == D .OR.      &
                       G == F .OR. G == O .OR. G == A .OR.      &
                       G == N)  CYCLE
                   RED    = R*100 + E*10 + D
                   FOR    = F*100 + O*10 + R
                   DANGER = D*100000 + A*10000 + N*1000 + G*100 + E*10 + R
                   IF (RED * FOR == DANGER) THEN
                      Count = Count + 1
                      WRITE(*,*) 'Solution ', Count, ':'
                      WRITE(*,*) '     RED = ', RED
                      WRITE(*,*) '     FOR = ', FOR
                      WRITE(*,*) '  DANGER = ', DANGER
                      WRITE(*,*)
                   END IF
                 END DO
               END DO
             END DO
           END DO
         END DO
       END DO
     END DO
   END DO

END PROGRAM  Puzzle

