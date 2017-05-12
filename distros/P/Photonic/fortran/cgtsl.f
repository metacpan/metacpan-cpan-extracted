*DECK CGTSL
      SUBROUTINE cgtsl (N, C, D, E, B, INFO)
C***BEGIN PROLOGUE  CGTSL
C***PURPOSE  Solve a tridiagonal linear system.
C***LIBRARY   SLATEC (LINPACK)
C***CATEGORY  D2C2A
C***TYPE      COMPLEX (SGTSL-S, DGTSL-D, CGTSL-C)
C***KEYWORDS  LINEAR ALGEBRA, LINPACK, MATRIX, SOLVE, TRIDIAGONAL
C***AUTHOR  Dongarra, J., (ANL)
C***DESCRIPTION
C
C     CGTSL given a general tridiagonal matrix and a right hand
C     side will find the solution.
C
C     On Entry
C
C        N       INTEGER
C                is the order of the tridiagonal matrix.
C
C        C       COMPLEX(N)
C                is the subdiagonal of the tridiagonal matrix.
C                C(2) through C(N) should contain the subdiagonal.
C                On output C is destroyed.
C
C        D       COMPLEX(N)
C                is the diagonal of the tridiagonal matrix.
C                On output D is destroyed.
C
C        E       COMPLEX(N)
C                is the superdiagonal of the tridiagonal matrix.
C                E(1) through E(N-1) should contain the superdiagonal.
C                On output E is destroyed.
C
C        B       COMPLEX(N)
C                is the right hand side vector.
C
C     On Return
C
C        B       is the solution vector.
C
C        INFO    INTEGER
C                = 0 normal value.
C                = K if the K-th element of the diagonal becomes
C                    exactly zero.  The subroutine returns when
C                    this is detected.
C
C***REFERENCES  J. J. Dongarra, J. R. Bunch, C. B. Moler, and G. W.
C                 Stewart, LINPACK Users' Guide, SIAM, 1979.
C***ROUTINES CALLED  (NONE)
C***REVISION HISTORY  (YYMMDD)
C   780814  DATE WRITTEN
C   890831  Modified array declarations.  (WRB)
C   890831  REVISION DATE from Version 3.2
C   891214  Prologue converted to Version 4.0 format.  (BAB)
C   900326  Removed duplicate information from DESCRIPTION section.
C           (WRB)
C   920501  Reformatted the REFERENCES section.  (WRB)
C***END PROLOGUE  CGTSL
      INTEGER n,info
      COMPLEX*16 c(*),d(*),e(*),b(*)
C
      INTEGER k,kb,kp1,nm1,nm2
      COMPLEX*16 t
      COMPLEX*16 zdum
      REAL cabs1
      cabs1(zdum) = abs(REAL(zdum)) + abs(aimag(zdum))
C***FIRST EXECUTABLE STATEMENT  CGTSL
         info = 0
         c(1) = d(1)
         nm1 = n - 1
         IF (nm1 .LT. 1) go to 40
            d(1) = e(1)
            e(1) = (0.0e0,0.0e0)
            e(n) = (0.0e0,0.0e0)
C
            DO 30 k = 1, nm1
               kp1 = k + 1
C
C              FIND THE LARGEST OF THE TWO ROWS
C
               IF (cabs1(c(kp1)) .LT. cabs1(c(k))) go to 10
C
C                 INTERCHANGE ROW
C
                  t = c(kp1)
                  c(kp1) = c(k)
                  c(k) = t
                  t = d(kp1)
                  d(kp1) = d(k)
                  d(k) = t
                  t = e(kp1)
                  e(kp1) = e(k)
                  e(k) = t
                  t = b(kp1)
                  b(kp1) = b(k)
                  b(k) = t
   10          CONTINUE
C
C              ZERO ELEMENTS
C
               IF (cabs1(c(k)) .NE. 0.0e0) go to 20
                  info = k
                  go to 100
   20          CONTINUE
               t = -c(kp1)/c(k)
               c(kp1) = d(kp1) + t*d(k)
               d(kp1) = e(kp1) + t*e(k)
               e(kp1) = (0.0e0,0.0e0)
               b(kp1) = b(kp1) + t*b(k)
   30       CONTINUE
   40    CONTINUE
         IF (cabs1(c(n)) .NE. 0.0e0) go to 50
            info = n
         go to 90
   50    CONTINUE
C
C           BACK SOLVE
C
            nm2 = n - 2
            b(n) = b(n)/c(n)
            IF (n .EQ. 1) go to 80
               b(nm1) = (b(nm1) - d(nm1)*b(n))/c(nm1)
               IF (nm2 .LT. 1) go to 70
               DO 60 kb = 1, nm2
                  k = nm2 - kb + 1
                  b(k) = (b(k) - d(k)*b(k+1) - e(k)*b(k+2))/c(k)
   60          CONTINUE
   70          CONTINUE
   80       CONTINUE
   90    CONTINUE
  100 CONTINUE
C
      RETURN
      END
