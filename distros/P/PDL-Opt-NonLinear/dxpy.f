C%% TRUNCATED-NEWTON METHOD: BLAS
C   NOTE: ALL ROUTINES HERE ARE FROM LINPACK WITH THE EXCEPTION
C         OF DXPY (A VERSION OF DAXPY WITH A=1.0)
C   WRITTEN BY:  STEPHEN G. NASH
C                OPERATIONS RESEARCH AND APPLIED STATISTICS DEPT.
C                GEORGE MASON UNIVERSITY
C                FAIRFAX, VA 22030

C******************************************************************
C SPECIAL BLAS FOR Y = X+Y
C******************************************************************
      SUBROUTINE DXPY(N,DX,INCX,DY,INCY)
      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
C
C     VECTOR PLUS A VECTOR.
C     USES UNROLLED LOOPS FOR INCREMENTS EQUAL TO ONE.
C     STEPHEN G. NASH 5/30/89.
C
      DOUBLE PRECISION DX(1),DY(1)
      INTEGER I,INCX,INCY,IX,IY,M,MP1,N
C
      IF(N.LE.0)RETURN
      IF(INCX.EQ.1.AND.INCY.EQ.1)GO TO 20
C
C        CODE FOR UNEQUAL INCREMENTS OR EQUAL INCREMENTS
C          NOT EQUAL TO 1
C
      IX = 1
      IY = 1
      IF(INCX.LT.0)IX = (-N+1)*INCX + 1
      IF(INCY.LT.0)IY = (-N+1)*INCY + 1
      DO 10 I = 1,N
        DY(IY) = DY(IY) + DX(IX)
        IX = IX + INCX
        IY = IY + INCY
   10 CONTINUE
      RETURN
C
C        CODE FOR BOTH INCREMENTS EQUAL TO 1
C
C
C        CLEAN-UP LOOP
C
   20 M = MOD(N,4)
      IF( M .EQ. 0 ) GO TO 40
      DO 30 I = 1,M
        DY(I) = DY(I) + DX(I)
   30 CONTINUE
      IF( N .LT. 4 ) RETURN
   40 MP1 = M + 1
      DO 50 I = MP1,N,4
        DY(I) = DY(I) + DX(I)
        DY(I + 1) = DY(I + 1) + DX(I + 1)
        DY(I + 2) = DY(I + 2) + DX(I + 2)
        DY(I + 3) = DY(I + 3) + DX(I + 3)
   50 CONTINUE
      RETURN
      END
