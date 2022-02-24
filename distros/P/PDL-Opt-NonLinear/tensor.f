C      ALGORITHM 739, COLLECTED ALGORITHMS FROM ACM.
C      THIS WORK PUBLISHED IN TRANSACTIONS ON MATHEMATICAL SOFTWARE,
C      VOL. 20, NO. 4, DECEMBER, 1994, P.518-530.
c*** tensrd.f
C  ----------------------
C  |  T E N S O R       |
C  ----------------------
      SUBROUTINE TENSOR(NR,N,X,FCN,GRD,HSN,TYPX,FSCALE,GRADTL,STEPTL,
     Z                  ITNLIM,STEPMX,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,
     Z                  MSG,XPLS,FPLS,GPLS,H,ITNNO,WRK,IWRK)
C
C AUTHORS:   TA-TUNG CHOW, ELIZABETH ESKOW AND ROBERT B. SCHNABEL
C
C DATE:      MARCH 29, 1991
C
C PURPOSE:
C   DERIVATIVE TENSOR METHOD FOR UNCONSTRAINED OPTIMIZATION 
C     THE METHOD BASES EACH ITERATION ON A SPECIALLY CONSTRUCTED
C     FOURTH ORDER MODEL OF THE OBJECTIVE FUNCTION.  THE MODEL
C     INTERPOLATES THE FUNCTION VALUE AND GRADIENT FROM THE PREVIOUS
C     ITERATE AND THE CURRENT FUNCTION VALUE, GRADIENT AND HESSIAN
C     MATRIX.
C
C BLAS SUBROUTINES: DCOPY,DDOT,DSCAL
C UNCMIN SUBROUTINES: DFAULT, OPTCHK, GRDCHK, HESCHK, LNSRCH, FSTOFD,
C                     SNDOFD, BAKSLV, FORSLV, OPTSTP
C MODCHL SUBROUTINES: MODCHL, INIT, GERCH, FIN2X2
C
C-----------------------------------------------------------------------
C
C PARAMETERS:
C
C   NR      --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   X(N)    --> INITIAL GUESS (INPUT) AND CURRENT POINT
C   FCN     --> NAME OF SUBROUTINE TO EVALUATE FUNCTION VALUE
C   GRD     --> NAME OF SUBROUTINE TO EVALUATE ANALYTICAL GRADIENT
C   HSN     --> NAME OF SUBROUTINE TO EVALUATE ANALYTICAL HESSIAN
C               HSN SHOULD FILL ONLY THE LOWER TRIANGULAR PART
C               AND DIAGONAL OF H             
C   TYPX(N) --> TYPICAL SIZE OF EACH COMPONENT OF X
C   FSCALE  --> ESTIMATE OF SCALE OF OBJECTIVE FUNCTION FCN
C   GRADTL  --> GRADIENT TOLERANCE
C   STEPTL  --> STEP TOLERANCE
C   ITNLIM  --> ITERATION LIMIT
C   STEPMX  --> MAXIMUM STEP LENGTH ALLOWED
C   IPR     --> OUTPUT UNIT NUMBER
C   METHOD  --> IF VALUE IS 0 THEN USE ONLY NEWTON STEP AT
C               EACH ITERATION
C               IF VALUE IS 1 THEN TRY BOTH TENSOR AND NEWTON
C               STEPS AT EACH ITERATION
C   GRDFLG  --> = 1 OR 2 IF ANALYTICAL GRADIENT IS SUPPLIED
C   HESFLG  --> = 1 OR 2 IF ANALYTICAL HESSIAN IS SUPPLIED
C   NDIGIT  --> NUMBER OF GOOD DIGITS IN OPTIMIZATION FUNCTION FCN
C   MSG     --> OUTPUT MESSAGE CONTROL
C   XPLS(N) <--  NEW POINT AND FINAL POINT (OUTPUT)
C   FPLS    <--  NEW FUNCTION VALUE AND FINAL FUNCTION VALUE (OUTPUT)
C   GPLS(N) <--  CURRENT GRADIENT AND GRADIENT AT FINAL POINT (OUTPUT)
C   H(N,N)  --> HESSIAN
C   ITNNO   <--  NUMBER OF ITERATIONS
C   WRK(N,8)--> WORK SPACE
C   IWRK(N) --> WORK SPACE
C
      
      INTEGER NR,N,ITNLIM,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,MSG
      INTEGER ITNNO,IWRK(N)
      DOUBLE PRECISION X(N),TYPX(N),FSCALE,GRADTL,STEPTL,STEPMX
      DOUBLE PRECISION XPLS(N),FPLS,GPLS(N),H(NR,N),WRK(NR,8),FPLSA(1)
      EXTERNAL FCN,GRD,HSN
C
C   EQUIVALENCE WRK(N,1) = G(N)
C               WRK(N,2) = S(N)
C               WRK(N,3) = D(N)
C               WRK(N,4) = DN(N)
C               WRK(N,6) = E(N)
C               WRK(N,7) = WK1(N)
C               WRK(N,8) = WK2(N)
C
      FPLSA(1) = FPLS
      CALL OPT(NR,N,X,FCN,GRD,HSN,TYPX,FSCALE,GRADTL,STEPTL,
     Z         ITNLIM,STEPMX,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,
     Z         MSG,XPLS,FPLSA,GPLS,H,ITNNO,
     Z         WRK(1,1),WRK(1,2),WRK(1,3),WRK(1,4),
     Z         WRK(1,6),WRK(1,7),WRK(1,8),IWRK)
      RETURN
      END
C  ----------------------
C  |  T E N S R D       |
C  ----------------------
      SUBROUTINE TENSRD(NR,N,X,FCN,GRD,HSN,MSG,XPLS,FPLS,
     Z                  GPLS,H,ITNNO,WRK,IWRK)
C
C PURPOSE:
C   SHORT CALLING SEQUENCE SUBROUTINE
C
C-----------------------------------------------------------------------
C
C PARAMETERS:
C
C   NR         --> ROW DIMENSION OF MATRIX
C   N          --> DIMENSION OF PROBLEM
C   X(N)       --> INITIAL GUESS (INPUT) AND CURRENT POINT
C   FCN        --> NAME OF SUBROUTINE TO EVALUATE FUNCTION VALUE
C   MSG        --> OUTPUT MESSAGE CONTROL
C   XPLS(N)    <--  NEW POINT AND FINAL POINT (OUTPUT)
C   FPLS       <--  NEW FUNCTION VALUE AND FINAL FUNCTION VALUE (OUTPUT)
C   GPLS(N)    <--  GRADIENT AT FINAL POINT (OUTPUT)
C   H(N,N)     --> HESSIAN
C   ITNNO      <--  NUMBER OF ITERATIONS
C   WRK(N,8)   --> WORK SPACE
C   IWRK(N)    --> WORK SPACE
C vanuxemg@yahoo.fr (2/27/2005): Add name of function in parameter
      
      INTEGER NR,N,MSG,ITNNO,IWRK(N) 
      DOUBLE PRECISION X(N),XPLS(N),FPLS,GPLS(N),H(NR,N),WRK(NR,8)
      DOUBLE PRECISION FSCALE,GRADTL,STEPTL,STEPMX
      INTEGER GRDFLG,HESFLG,ITNLIM,IPR,METHOD,NDIGIT
      EXTERNAL FCN,GRD,HSN
C
C   EQUIVALENCE WRK(N,1) = G(N)
C               WRK(N,2) = S(N)
C               WRK(N,3) = D(N)
C               WRK(N,4) = DN(N)
C               WRK(N,5) = TYPX(N)
C               WRK(N,6) = E(N)
C               WRK(N,7) = WK1(N)
C               WRK(N,8) = WK2(N)
C
      CALL DFAULT(N,WRK(1,5),FSCALE,GRADTL,STEPTL,ITNLIM,STEPMX,IPR,
     Z             METHOD,GRDFLG,HESFLG,NDIGIT,MSG)
      CALL TENSOR(NR,N,X,FCN,GRD,HSN,WRK(1,5),FSCALE,GRADTL,STEPTL,
     Z            ITNLIM,STEPMX,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,
     Z            MSG,XPLS,FPLS,GPLS,H,ITNNO,WRK,IWRK)
      END

C  ----------------------
C  |       O P T        |
C  ----------------------
      SUBROUTINE OPT(NR,N,X,FCN,GRD,HSN,TYPX,FSCALE,GRADTL,STEPTL,
     Z               ITNLIM,STEPMX,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,
     Z               MSG,XPLS,FPLS,GPLS,H,ITNNO,G,S,D,DN,E,WK1,WK2,
     Z               PIVOT)
C
C PURPOSE:
C   DERIVATIVE TENSOR METHODS FOR UNCONSTRAINED OPTIMIZATION 
C
C-----------------------------------------------------------------------
C
C PARAMETERS:
C
C   NR      --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   X(N)    --> INITIAL GUESS (INPUT) AND CURRENT POINT
C   FCN     --> NAME OF SUBROUTINE TO EVALUATE FUNCTION VALUE
C               FCN: R(N) --> R(1)
C   GRD     --> NAME OF SUBROUTINE TO EVALUATE ANALYTICAL GRADIENT
C               FCN: R(N) --> R(N)
C   HSN     --> NAME OF SUBROUTINE TO EVALUATE ANALYTICAL HESSIAN
C               FCN: R(N) --> R(N X N)
C               HSN SHOULD FILL ONLY THE LOWER TRIANGULAR PART
C               AND DIAGONAL OF H
C   TYPX(N) --> TYPICAL SIZE OF EACH COMPONENT OF X
C   FSCALE  --> ESTIMATE OF SCALE OF OBJECTIVE FUNCTION FCN
C   GRADTL  --> GRADIENT TOLERANCE
C   STEPTL  --> STEP TOLERANCE
C   ITNLIM  --> ITERATION LIMIT
C   STEPMX  --> MAXIMUM STEP LENGTH ALLOWED
C   IPR     --> OUTPUT UNIT NUMBER
C   METHOD  --> IF VALUE IS 0 THEN USE ONLY NEWTON STEP AT
C               EACH ITERATION
C   GRDFLG  --> = 1 OR 2 IF ANALYTICAL GRADIENT IS SUPPLIED
C   HESFLG  --> = 1 OR 2 IF ANALYTICAL HESSIAN IS SUPPLIED
C   NDIGIT  --> NUMBER OF GOOD DIGITS IN OPTIMIZATION FUNCTION FCN
C   MSG     --> OUTPUT MESSAGE CONTRO
C   XPLS(N) <--  NEW POINT AND FINAL POINT (OUTPUT)
C   FPLS    <--  NEW FUNCTION VALUE AND FINAL FUNCTION VALUE (OUTPUT)
C   GPLS(N) <--  CURRENT GRADIENT AND GRADIENT AT FINAL POINT (OUTPUT)
C   H(N,N)  --> HESSIAN
C   ITNNO   <--  NUMBER OF ITERATIONS
C   G(N)    --> PREVIOUS GRADIENT
C   S       --> STEP TO PREVIOUS ITERATE (FOR TENSOR MODEL)
C   D       --> CURRENT STEP (TENSOR OR NEWTON)
C   DN      --> NEWTON STEP
C   E(N)    --> DIAGONAL ADDED TO HESSIAN IN CHOLESKY DECOMPOSITION
C   WK1(N)  --> WORKSPACE
C   WK2(N)  --> WORKSPACE
C   PIVOT(N)--> PIVOT VECTOR FOR CHOLESKY DECOMPOSITION
C
      
      INTEGER NR,N,ITNLIM,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,MSG
      INTEGER ITNNO,PIVOT(N),ICSCMX,I,ITRMCD,IRETCD,IMSG,NFCNT
      DOUBLE PRECISION F(1),FP,GPLS(N),G(N),H(NR,N),S(N)
      DOUBLE PRECISION D(N),WK1(N),TYPX(N),FSCALE,GRADTL,STEPTL
      DOUBLE PRECISION X(N),STEPMX,FINIT
      DOUBLE PRECISION WK2(N),FPLS(1),XPLS(N),E(N)
      DOUBLE PRECISION DN(N),EPS,RNF,ANALTL,GNORM,TWONRM
      DOUBLE PRECISION ADDMAX,TEMP,ALPHA,BETA,GD,FN,DDOT
      DOUBLE PRECISION RGX,RSX
      LOGICAL NOMIN,MXTAKE
      EXTERNAL FCN,GRD,HSN,DCOPY,DDOT
C--------------------------------   
C     INITIALIZATION           |
C--------------------------------
C
      ITNNO=0
      ICSCMX=0
      NFCNT=0

      CALL MCHEPS(EPS)
      CALL OPTCHK(NR,N,MSG,X,TYPX,FSCALE,GRADTL,STEPTL,ITNLIM,
     +     NDIGIT,EPS,METHOD,GRDFLG,HESFLG,STEPMX,IPR)
      IF (MSG.LT.0) RETURN

      
C
C     SCALE X
      DO 10 I=1,N
        X(I)=X(I)/TYPX(I)
10    CONTINUE
C
C--------------------------------
C     INITIAL ITERATION |
C--------------------------------
C
C     COMPUTE TYPICAL SIZE OF X 
      DO 15 I=1,N
        DN(I)=1D0/TYPX(I)
15    CONTINUE
      RNF=MAX(10.0D0**(-NDIGIT),EPS)
      ANALTL=MAX(1D-2,SQRT(RNF))
C     UNSCALE X AND COMPUTE F AND G
      DO 20 I=1,N
        WK1(I)=X(I)*TYPX(I)
20    CONTINUE
      CALL FCN(N,WK1,F(1))
      NFCNT=NFCNT+1
      IF(GRDFLG .GE. 1)THEN
        CALL GRD(N,WK1,G)
        IF(GRDFLG .EQ. 1)THEN
          FSCALE=1D0
          CALL GRDCHK(N,WK1,FCN,F(1),G,DN,TYPX,FSCALE,RNF,ANALTL,WK2,
     Z                    MSG,IPR,NFCNT)
        END IF
      ELSE
        CALL FSTOFD(1,1,N,WK1,FCN,F,G,TYPX,RNF,WK2,1,NFCNT)
      END IF
      IF(MSG .LT. -20) THEN
        RETURN
      END IF
C
      GNORM=TWONRM(N,G)
C
C     PRINT OUT 1ST ITERATION?
      IF(MSG .GE. 1)THEN
        WRITE(IPR,25)F(1)
25      FORMAT(' INITIAL FUNCTION VALUE F=',E20.13)
        WRITE(IPR,30)(G(I),I=1,N)
30      FORMAT(' INITIAL GRADIENT G=',999E20.13)
      END IF
C
C     TEST WHETHER THE INITIAL GUESS SATISFIES THE STOPPING CRITERIA
      IF(GNORM .LE. GRADTL)THEN
        FPLS(1)=F(1)
        DO 40,I=1,N
           XPLS(I)=X(I)
           GPLS(I)=G(I)
40      CONTINUE
        CALL OPTSTP(N,XPLS,FPLS(1),GPLS,X,ITNNO,ICSCMX,
     Z            ITRMCD,GRADTL,STEPTL,FSCALE,ITNLIM,IRETCD,
     Z            MXTAKE,IPR,MSG,RGX,RSX)   
        GO TO 350
      END IF
      FINIT=F(1)
C
C------------------------
C     ITERATION 1 |
C------------------------
C
      ITNNO=ITNNO+1
C
C     COMPUTE HESSIAN
      IF(HESFLG .EQ. 0)THEN
        IF (GRDFLG .EQ. 1)  THEN
           CALL FSTOFD(NR,N,N,WK1,GRD,G,H,TYPX,RNF,WK2,3,NFCNT)
        ELSE
           CALL SNDOFD(NR,N,WK1,FCN,F(1),H,TYPX,RNF,WK2,D,NFCNT)
        END IF
      ELSE
        IF(HESFLG .EQ. 2)THEN
          CALL HSN(NR,N,WK1,H)
        ELSE
          IF(HESFLG .EQ. 1)THEN
C           IN HESCHK GPLS,XPLS AND E ARE USED AS WORK SPACE
            CALL HESCHK(NR,N,WK1,FCN,GRD,HSN,F(1),G,H,DN,TYPX,RNF,
     Z                    ANALTL,GRDFLG,GPLS,XPLS,E,MSG,IPR,NFCNT)
          END IF
        END IF
      END IF
      IF(MSG .LT. -20)RETURN
      DO 50 I=2,N
         CALL DCOPY(I-1,H(I,1),NR,H(1,I),1)
50    CONTINUE
C
C     CHOLESKY DECOMPOSITION FOR H (H=LLT)
      CALL CHOLDR(NR,N,H,D,EPS,PIVOT,E,WK1,ADDMAX)
C
C     SOLVE FOR NEWTON STEP D
      DO 60 I=1,N
60       WK2(I)=-G(I)
      CALL FORSLV(NR,N,H,WK1,WK2)
      CALL BAKSLV(NR,N,H,D,WK1)
      
C
C     APPLY LINESEARCH TO THE NEWTON STEP
      CALL LNSRCH(NR,N,X,F(1),G,D,XPLS,FPLS(1),MXTAKE,IRETCD,STEPMX,
     Z                STEPTL,TYPX,FCN,WK1,NFCNT)
C
C     UPDATE G
C      CALL DCOPY(N,GPLS(1),1,GP(1),1)
C
C     UNSCALE XPLS AND COMPUTE GPLS
      DO 80 I=1,N
         WK1(I)=XPLS(I)*TYPX(I)
80    CONTINUE
      IF(GRDFLG .GE. 1)THEN
        CALL GRD(N,WK1,GPLS)
      ELSE
        CALL FSTOFD(1,1,N,WK1,FCN,FPLS,GPLS,TYPX,RNF,WK2,1,NFCNT)
      END IF
C
C     CHECK STOPPING CONDITIONS
      CALL OPTSTP(N,XPLS,FPLS(1),GPLS,X,ITNNO,ICSCMX,
     Z            ITRMCD,GRADTL,STEPTL,FSCALE,ITNLIM,IRETCD,
     Z            MXTAKE,IPR,MSG,RGX,RSX)   
C
C     IF ITRMCD > 0 THEN STOPPING CONDITIONS SATISFIED
      IF(ITRMCD .GT. 0)GO TO 350
C
C     UPDATE X,F AND S FOR TENSOR MODEL
      FP=F(1)
      F(1)=FPLS(1)
      DO 90 I=1,N
        TEMP=XPLS(I)
        S(I)=X(I)-TEMP
        X(I)=TEMP
90    CONTINUE
      
C
C     IF MSG >= 2 THEN PRINT OUT EACH ITERATION
      IF(MSG .GE. 2)THEN
        WRITE (IPR,103)ITNNO 
103     FORMAT(' -----------    ITERATION ',I4,' ----------------')
          WRITE(IPR,104)(X(I),I=1,N)
104     FORMAT(' X=',999E20.13)
        WRITE(IPR,105)FPLS(1)
105     FORMAT(' F(X)=',E20.13)
        WRITE(IPR,106)(GPLS(I),I=1,N)
106     FORMAT(' G(X)=',999E20.13)
      END IF
      IF (MSG .GE. 3 )THEN
		WRITE (IPR,108) NFCNT,RGX
108     FORMAT('FUNCTION EVAL COUNT:',I6,' REL. GRAD. MAX:',E20.13)
        WRITE (IPR,110) RSX
110     FORMAT('REL. STEP MAX :',E20.13)
      ENDIF

C
C------------------------
C     ITERATION > 1     |
C------------------------
C
C     UNSCALE X AND COMPUTE H
200   DO 210 I=1,N
        WK1(I)=X(I)*TYPX(I)
210   CONTINUE
      IF(HESFLG .EQ. 0)THEN
        IF (GRDFLG .EQ. 1)  THEN
           CALL FSTOFD(NR,N,N,WK1,GRD,G,H,TYPX,RNF,WK2,3,NFCNT)
        ELSE
           CALL SNDOFD(NR,N,WK1,FCN,F(1),H,TYPX,RNF,WK2,D,NFCNT)
        END IF
      ELSE  
        CALL HSN(NR,N,WK1,H)
      END IF
      DO 230 I=2,N
         CALL DCOPY(I-1,H(I,1),NR,H(1,I),1)
230   CONTINUE
C
C     IF METHOD = 0 THEN USE NEWTON STEP ONLY
      IF (METHOD .EQ. 0)  THEN
C
C       CHOLESKY DECOMPOSITION FOR H
        CALL CHOLDR(NR,N,H,WK2,EPS,PIVOT,E,WK1,ADDMAX)
C
C       COMPUTE NEWTON STEP
        DO 240 I=1,N
          WK1(I)=-GPLS(I)
240     CONTINUE
        CALL FORSLV(NR,N,H,WK2,WK1)
        CALL BAKSLV(NR,N,H,D,WK2)
C
C       NO TENSOR STEP
        NOMIN=.TRUE.
        GO TO 300
C
      END IF
C
C     FORM TENSOR MODEL
      CALL MKMDL(NR,N,F(1),FP,GPLS,G,S,H,ALPHA,BETA,WK1,D)
C
C   SOLVE TENSOR MODEL AND COMPUTE NEWTON STEP
C   ON INPUT : SH IS STORED IN WK1
C            A=(G-GPLS-SH-S*BETA/(6*STS)) IS STORED IN D
C   ON OUTPUT: NEWTON STEP IS STORED IN DN
C            TENSOR STEP IS STORED IN D
      CALL SLVMDL(NR,N,H,XPLS,WK2,E,G,S,GPLS,PIVOT,D,WK1,DN,
     Z                ALPHA,BETA,NOMIN,EPS)
C
C     IF TENSOR MODEL HAS NO MINIMIZER THEN USE NEWTON STEP
      IF(NOMIN)THEN
        CALL DCOPY(N,DN(1),1,D(1),1)
        GO TO 300
      END IF
C
C     IF TENSOR STEP IS NOT IN DESCENT DIRECTION THEN USE NEWTON STEP

      GD = DDOT(N,GPLS(1),1,D(1),1)
      IF(GD .GT. 0D0)THEN
        CALL DCOPY(N,DN(1),1,D(1),1)
        NOMIN=.TRUE.
      END IF
C
300   ITNNO=ITNNO+1
      CALL DCOPY(N,GPLS(1),1,G(1),1)
C
C     APPLY LINESEARCH TO TENSOR (OR NEWTON) STEP
      CALL LNSRCH(NR,N,X,F(1),G,D,XPLS,FPLS(1),MXTAKE,IRETCD,STEPMX,
     Z                STEPTL,TYPX,FCN,WK1,NFCNT)
C
      IF(.NOT. NOMIN)THEN
C       TENSOR STEP IS FOUND AND IN DESCENT DIRECTION, 
C       APPLY LINESEARCH TO NEWTON STEP
C       NEW NEWTON POINT IN WK2
        CALL LNSRCH(NR,N,X,F(1),G,DN,WK2,FN,MXTAKE,IRETCD,STEPMX,
     Z                STEPTL,TYPX,FCN,WK1,NFCNT)
C
C       COMPARE TENSOR STEP TO NEWTON STEP
C       IF NEWTON STEP IS BETTER, SET NEXT ITERATE TO NEW NEWTON POINT
        IF(FN .LT. FPLS(1))THEN
          FPLS(1)=FN
          CALL DCOPY(N,DN(1),1,D(1),1)
          CALL DCOPY(N,WK2(1),1,XPLS(1),1)
        END IF
      END IF
      DO 320 I=1,N
        D(I)=XPLS(I)-X(I)
320   CONTINUE
C
C     UNSCALE XPLS, AND COMPUTE FPLS AND GPLS
      DO 330 I=1,N
         WK1(I)=XPLS(I)*TYPX(I)
330   CONTINUE
      CALL FCN(N,WK1,FPLS(1))
      NFCNT=NFCNT+1
      IF(GRDFLG .GE. 1)THEN
        CALL GRD(N,WK1,GPLS)
      ELSE
        CALL FSTOFD(1,1,N,WK1,FCN,FPLS,GPLS,TYPX,RNF,WK2,1,NFCNT)
      END IF
C
C     CHECK STOPPING CONDITIONS
      IMSG=MSG
      CALL OPTSTP(N,XPLS,FPLS(1),GPLS,X,ITNNO,ICSCMX,
     Z            ITRMCD,GRADTL,STEPTL,FSCALE,ITNLIM,IRETCD,
     Z            MXTAKE,IPR,MSG,RGX,RSX)   
C
C     IF ITRMCD = 0 THEN NOT OVER YET
      IF(ITRMCD .EQ. 0)GO TO 500
C
C     IF MSG >= 1 THEN PRINT OUT FINAL ITERATION
350   IF(IMSG .GE. 1)THEN
C
C       TRANSFORM X BACK TO ORIGINAL SPACE
        DO 360 I=1,N
          XPLS(I)=XPLS(I)*TYPX(I) 
360     CONTINUE
        WRITE(IPR,370)(XPLS(I),I=1,N)
370     FORMAT(' FINAL X=',999E20.13)
        WRITE(IPR,380)(GPLS(I),I=1,N)
380     FORMAT(' GRADIENT G=',999E20.13)
        WRITE(IPR,390)FPLS(1),ITNNO
390     FORMAT(' FUNCTION VALUE F(X)=',E20.13,
     Z         ' AT ITERATION ',I4) 
        IF (IMSG .GE. 3) THEN
		WRITE (IPR,400) NFCNT,RGX
400     FORMAT('FUNCTION EVAL COUNT:',I6,' REL. GRAD. MAX:',E20.13)
        WRITE (IPR,410) RSX
410     FORMAT('REL. STEP MAX :',E20.13)
      ENDIF

C       UPDATE THE HESSIAN
        IF(HESFLG .EQ. 0)THEN
           IF (GRDFLG .EQ. 1)  THEN
              CALL FSTOFD(NR,N,N,XPLS,GRD,GPLS,H,TYPX,RNF,WK2,3,NFCNT)
           ELSE
              CALL SNDOFD(NR,N,XPLS,FCN,FPLS(1),H,TYPX,RNF,WK2,D,NFCNT)
           END IF
        ELSE  
          CALL HSN(NR,N,XPLS,H)
        END IF
      END IF
      RETURN
C
C     UPDATE INFORMATION AT THE CURRENT POINT
500   CALL DCOPY(N,XPLS(1),1,X(1),1)
      DO 550 I=1,N
        S(I)=-D(I)
550   CONTINUE
C
C     IF TOO MANY ITERATIONS THEN RETURN
      IF(ITNNO .GT. ITNLIM)GO TO 350
C
C     IF MSG >= 2 THEN PRINT OUT EACH ITERATION
      IF(MSG .GE. 2)THEN
        WRITE (IPR,560)ITNNO
560     FORMAT(' -----------    ITERATION ',I4,' ----------------')
          WRITE(IPR,570)(X(I),I=1,N)
570     FORMAT(' X=',999E20.13)
        WRITE(IPR,580)FPLS(1)
580     FORMAT(' F(X)=',E20.13)
        WRITE(IPR,590)(GPLS(I),I=1,N)
590     FORMAT(' G(X)=',999E20.13)
      END IF
      IF (MSG .GE. 3) THEN
		WRITE (IPR,600) NFCNT,RGX
600     FORMAT('FUNCTION EVAL COUNT:',I6,' REL. GRAD. MAX:',E20.13)
        WRITE (IPR,610) RSX
610     FORMAT('REL. STEP MAX :',E20.13)
      ENDIF

C     UPDATE F
      FP=F(1)
      F(1)=FPLS(1)
C
C     PERFORM NEXT ITERATION
      GO TO 200
C
C     END OF ITERATION > 1
C
      END
C  ----------------------
C  |  D F A U L T      |
C  ----------------------
      SUBROUTINE DFAULT(N,TYPX,FSCALE,GRADTL,STEPTL,ITNLIM,
     Z                  STEPMX,IPR,METHOD,GRDFLG,HESFLG,NDIGIT,MSG)
      
      INTEGER N,ITNLIM,IPR,METHOD,NDIGIT,MSG,GRDFLG,HESFLG,I
      DOUBLE PRECISION TYPX(N),FSCALE,GRADTL,STEPTL,STEPMX,EPS,TEMP 
      CALL MCHEPS(EPS)
      METHOD=1
      FSCALE=1D0
      GRDFLG=0
      HESFLG=0
      DO 1 I=1,N
        TYPX(I)=1D0
1     CONTINUE
      TEMP=EPS**(1D0/3D0)
      GRADTL=TEMP
      STEPTL=TEMP*TEMP
      NDIGIT=-LOG10(EPS)
C     SET ACTUAL DFAULT VALUE OF STEPMX IN OPTCHK
      STEPMX=0D0
      ITNLIM=100
      IPR=6
      MSG=1
      END
C  ----------------------
C  |  O P T C H K       |
C  ----------------------
      SUBROUTINE OPTCHK(NR,N,MSG,X,TYPX,FSCALE,GRADTL,STEPTL,
     +    ITNLIM,NDIGIT,EPS,METHOD,GRDFLG,HESFLG,STEPMX,IPR)

C                                                                       
C PURPOSE                                                               
C -------                                                               
C CHECK INPUT FOR REASONABLENESS                                        
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C NR          <--> ROW DIMENSION OF H AND WRK
C N            --> DIMENSION OF PROBLEM                                 
C X(N)         --> ON ENTRY, ESTIMATE TO ROOT OF FCN
C TYPX(N)     <--> TYPICAL SIZE OF EACH COMPONENT OF X                  
C FSCALE      <--> ESTIMATE OF SCALE OF OBJECTIVE FUNCTION FCN          
C GRADTL      <--> TOLERANCE AT WHICH GRADIENT CONSIDERED CLOSE         
C                  ENOUGH TO ZERO TO TERMINATE ALGORITHM                
C STEPTL      <--> TOLERANCE AT WHICH STEP LENGTH CONSIDERED CLOSE 
C                  ENOUGH TO ZERO TO TERMINATE ALGORITHM
C ITNLIM      <--> MAXIMUM NUMBER OF ALLOWABLE ITERATIONS               
C NDIGIT      <--> NUMBER OF GOOD DIGITS IN OPTIMIZATION FUNCTION FCN   
C EPS          --> MACHINE PRECISION
C METHOD      <--> ALGORITHM INDICATOR                                  
C GRDFLG      <--> =1 IF ANALYTIC GRADIENT SUPPLIED                     
C HESFLG      <--> =1 IF ANALYTIC HESSIAN SUPPLIED                      
C STEPMX      <--> MAXIMUM STEP SIZE
C MSG         <--> MESSAGE AND ERROR CODE                               
C IPR          --> DEVICE TO WHICH TO SEND OUTPUT                       
C                                                                       
      INTEGER NR,N,ITNLIM,IPR,METHOD,NDIGIT,MSG,GRDFLG,HESFLG,I
      DOUBLE PRECISION X(N),TYPX(N),FSCALE,GRADTL,STEPTL,STEPMX,EPS
      DOUBLE PRECISION STPSIZ,TEMP
      INTRINSIC LOG10, MAX, SQRT
C                                                                       
C CHECK DIMENSION OF PROBLEM                                            
C                                                                       
      IF(N.LE.0) GO TO 805                                              
      IF(NR.LT.N) GO TO 806
C                                                                       
C CHECK THAT PARAMETERS ONLY TAKE ON ACCEPTABLE VALUES.                 
C IF NOT, SET THEM TO DEFAULT VALUES.                                   
      IF(METHOD.NE.0) METHOD=1                                          
      IF(GRDFLG.NE.2 .AND. GRDFLG.NE.1) GRDFLG=0                        
      IF(HESFLG.NE.2 .AND. HESFLG.NE.1) HESFLG=0                        
      IF(MSG.GT.3 .OR. MSG.LT.0 .)  MSG=1                                 
C                                                                       
C COMPUTE SCALE MATRIX                                                  
C                                                                       
      DO 10 I=1,N                                                       
        IF(TYPX(I).EQ.0.) TYPX(I)=1D0                                   
        IF(TYPX(I).LT.0.) TYPX(I)=-TYPX(I)                              
   10 CONTINUE                                                          
C                 
C CHECK MAXIMUM STEP SIZE
C                 
      IF (STEPMX .GT. 0D0) GO TO 20
      STPSIZ = 0D0
      DO 15 I = 1, N
         STPSIZ = STPSIZ + X(I)*X(I)/TYPX(I)*TYPX(I)
   15 CONTINUE    
      STPSIZ = SQRT(STPSIZ)
      STEPMX = MAX(1D3*STPSIZ, 1D3)
   20 CONTINUE    
C CHECK FUNCTION SCALE                                                  
      IF(FSCALE.EQ.0.) FSCALE=1D0                                       
      IF(FSCALE.LT.0.) FSCALE=-FSCALE    
                                                                        
C CHECK GRADIENT TOLERANCE                                              
      IF(GRADTL.LT.0.) GRADTL=EPS**(1D0/3D0)                            
C CHECK STEP TOLERANCE                                                  
      IF(STEPTL.LT.0.) THEN
         TEMP=EPS**(1D0/3D0)
         STEPTL=TEMP*TEMP
      END IF 
C                                                                       
C CHECK ITERATION LIMIT                                                 
      IF(ITNLIM.LE.0) ITNLIM=100                                        
C                                                                       
C CHECK NUMBER OF DIGITS OF ACCURACY IN FUNCTION FCN                    
      IF(NDIGIT.LE.0) NDIGIT=-LOG10(EPS)                                
      IF(10D0**(-NDIGIT).LE.EPS) NDIGIT=-LOG10(EPS)
      RETURN
C                                                                       
C ERROR EXITS                                                           
C                                                                       
  805 WRITE(IPR,901) N                                                  
      MSG=-20                                                            
      RETURN 
  806 WRITE(IPR,902) NR,N
      MSG=-20
      RETURN
  901 FORMAT(32H0OPTCHK    ILLEGAL DIMENSION, N=,I5)                    
  902 FORMAT('OPTCHK    ILLEGAL INPUT VALUES OF: NR=',I5,', N=',I5,
     +       ', NR MUST BE <=  N.')
      END 
C  ----------------------
C  |  G R D C H K       |
C  ----------------------
      SUBROUTINE GRDCHK(N,X,FCN,F,G,TYPSIZ,TYPX,FSCALE,RNF,
     +     ANALTL,WRK1,MSG,IPR,IFN)
C                                                                       
C PURPOSE                                                               
C -------                                                               
C CHECK ANALYTIC GRADIENT AGAINST ESTIMATED GRADIENT                    
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C N            --> DIMENSION OF PROBLEM                                 
C X(N)         --> ESTIMATE TO A ROOT OF FCN                            
C FCN          --> NAME OF SUBROUTINE TO EVALUATE OPTIMIZATION FUNCTION 
C                  MUST BE DECLARED EXTERNAL IN CALLING ROUTINE         
C                       FCN:  R(N) --> R(1)                             
C F            --> FUNCTION VALUE:  FCN(X)                              
C G(N)         --> GRADIENT:  G(X)                                      
C TYPSIZ(N)    --> TYPICAL SIZE FOR EACH COMPONENT OF X                 
C FSCALE       --> ESTIMATE OF SCALE OF OBJECTIVE FUNCTION FCN          
C RNF          --> RELATIVE NOISE IN OPTIMIZATION FUNCTION FCN          
C ANALTL       --> TOLERANCE FOR COMPARISON OF ESTIMATED AND            
C                  ANALYTICAL GRADIENTS                                 
C WRK1(N)      --> WORKSPACE                                            
C MSG         <--  MESSAGE OR ERROR CODE                                
C                    ON OUTPUT: =-21, PROBABLE CODING ERROR OF GRADIENT 
C IPR          --> DEVICE TO WHICH TO SEND OUTPUT                       
C IFN         <--> NUMBER OF FUNCTION EVALUATIONS
      INTEGER N,MSG,IPR,IFN,KER,I
      DOUBLE PRECISION F(1),X(N),G(N),TYPX(N),FSCALE,ANALTL,RNF
      DOUBLE PRECISION TYPSIZ(N),GS,WRK(1)
      DOUBLE PRECISION WRK1(N)                                                 
      EXTERNAL FCN                                                      
      INTRINSIC ABS,MAX
C                                                                       
C COMPUTE FIRST ORDER FINITE DIFFERENCE GRADIENT AND COMPARE TO
C ANALYTIC GRADIENT.
C
      CALL FSTOFD(1,1,N,X,FCN,F,WRK1,TYPX,RNF,WRK,1,IFN)
      KER=0
      DO 5 I=1,N
        GS=MAX(ABS(F(1)),FSCALE)/MAX(ABS(X(I)),TYPSIZ(I))
        IF(ABS(G(I)-WRK1(I)).GT.MAX(ABS(G(I)),GS)*ANALTL) KER=1
    5 CONTINUE
      IF(KER.EQ.0) GO TO 20
        WRITE(IPR,901)
        WRITE(IPR,902) (I,G(I),WRK1(I),I=1,N)
        MSG=-21
   20 CONTINUE                                                          
      RETURN                                                            
  901 FORMAT(47H0GRDCHK    PROBABLE ERROR IN CODING OF ANALYTIC,        
     +       19H GRADIENT FUNCTION./                                    
     +       16H GRDCHK     COMP,12X,8HANALYTIC,12X,8HESTIMATE)         
  902 FORMAT(11H GRDCHK    ,I5,3X,E20.13,3X,E20.13)
      END                                                               
C  ----------------------
C  |  H E S C H K       |
C  ----------------------
      SUBROUTINE HESCHK(NR,N,X,FCN,GRD,HSN,F,G,A,TYPSIZ,TYPX,RNF,       
     +     ANALTL,IAGFLG,UDIAG,WRK1,WRK2,MSG,IPR,IFN)
C                                                                       
C PURPOSE                                                               
C -------                                                               
C CHECK ANALYTIC HESSIAN AGAINST ESTIMATED HESSIAN                      
C  (THIS MAY BE DONE ONLY IF THE USER SUPPLIED ANALYTIC HESSIAN         
C   HSN FILLS ONLY THE LOWER TRIANGULAR PART AND DIAGONAL OF A)         
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C NR           --> ROW DIMENSION OF MATRIX                              
C N            --> DIMENSION OF PROBLEM                                 
C X(N)         --> ESTIMATE TO A ROOT OF FCN                            
C FCN          --> NAME OF SUBROUTINE TO EVALUATE OPTIMIZATION FUNCTION 
C                  MUST BE DECLARED EXTERNAL IN CALLING ROUTINE         
C                       FCN:  R(N) --> R(1)                             
C GRD          --> NAME OF SUBROUTINE TO EVALUATE GRADIENT OF FCN.      
C                  MUST BE DECLARED EXTERNAL IN CALLING ROUTINE         
C HSN          --> NAME OF SUBROUTINE TO EVALUATE HESSIAN OF FCN.       
C                  MUST BE DECLARED EXTERNAL IN CALLING ROUTINE 
C                  HSN SHOULD FILL ONLY THE LOWER TRIANGULAR PART
C                  AND DIAGONAL OF A         
C F            --> FUNCTION VALUE:  FCN(X)                              
C G(N)        <--  GRADIENT:  G(X)                                      
C A(N,N)      <--  ON EXIT:  HESSIAN IN LOWER TRIANGULAR PART AND DIAG  
C TYPSIZ(N)    --> TYPICAL SIZE FOR EACH COMPONENT OF X                 
C RNF          --> RELATIVE NOISE IN OPTIMIZATION FUNCTION FCN          
C ANALTL       --> TOLERANCE FOR COMPARISON OF ESTIMATED AND            
C                  ANALYTICAL GRADIENTS                                 
C IAGFLG       --> =1 IF ANALYTIC GRADIENT SUPPLIED                     
C UDIAG(N)     --> WORKSPACE                                            
C WRK1(N)      --> WORKSPACE                                            
C WRK2(N)      --> WORKSPACE                                            
C MSG         <--> MESSAGE OR ERROR CODE                                
C                    ON INPUT : IF =1XX DO NOT COMPARE ANAL + EST HESS  
C                    ON OUTPUT: =-22, PROBABLE CODING ERROR OF HESSIAN  
C IPR          --> DEVICE TO WHICH TO SEND OUTPUT                       
C IFN         <--> NUMBER OF FUNCTION EVALUTATIONS                                                            
      
      INTEGER NR,N,MSG,IPR,KER,I,J,IAGFLG,JP1,IM1,IFN
      DOUBLE PRECISION F,X(N),G(N),TYPX(N),ANALTL,RNF
      DOUBLE PRECISION TYPSIZ(N)                                               
      DOUBLE PRECISION WRK1(N)
      DOUBLE PRECISION A(NR,1),UDIAG(N),WRK2(N),HS
      EXTERNAL FCN,GRD,HSN                                              
      INTRINSIC ABS,MAX
C
C COMPUTE FINITE DIFFERENCE APPROXIMATION A TO THE HESSIAN.
C                                                                       
      IF(IAGFLG.EQ.1) CALL FSTOFD(NR,N,N,X,GRD,G,A,TYPX,RNF,
     Z                              WRK1,3,IFN)

      IF(IAGFLG.NE.1) CALL SNDOFD(NR,N,X,FCN,F,A,TYPX,RNF,WRK1,
     Z                          WRK2,IFN)                               
C                                                                       
      KER=0                                                             
C                                                                       
C COPY LOWER TRIANGULAR PART OF "A" TO UPPER TRIANGULAR PART            
C AND DIAGONAL OF "A" TO UDIAG                                          
C                                                                       
      DO 30 J=1,N
        UDIAG(J)=A(J,J)
        IF(J.EQ.N) GO TO 30
        JP1=J+1
        DO 25 I=JP1,N
          A(J,I)=A(I,J)
   25   CONTINUE
   30 CONTINUE
C
C COMPUTE ANALYTIC HESSIAN AND COMPARE TO FINITE DIFFERENCE
C APPROXIMATION.
C
      DO 32, I=1,N
        DO 32, J=I,N
          A(J,I)=0D0
  32  CONTINUE
C
      CALL HSN(NR,N,X,A)
      DO 40 J=1,N
        HS=MAX(ABS(G(J)),1.0D0)/MAX(ABS(X(J)),TYPSIZ(J))
        IF(ABS(A(J,J)-UDIAG(J)).GT.MAX(ABS(UDIAG(J)),HS)*ANALTL)
     +       KER=1
        IF(J.EQ.N) GO TO 40
        JP1=J+1
        DO 35 I=JP1,N
          IF(ABS(A(I,J)-A(J,I)).GT.MAX(ABS(A(I,J)),HS)*ANALTL) KER=1
   35   CONTINUE
   40 CONTINUE
C
      IF(KER.EQ.0) GO TO 90
        WRITE(IPR,901)
        DO 50 I=1,N
          IF(I.EQ.1) GO TO 45
          IM1=I-1
          DO 43 J=1,IM1
            WRITE(IPR,902) I,J,A(I,J),A(J,I)
   43     CONTINUE
   45     WRITE(IPR,902) I,I,A(I,I),UDIAG(I)
   50   CONTINUE
        MSG=-22
C     ENDIF                                                             
   90 CONTINUE                                                          
      RETURN                                                            
  901 FORMAT(47H HESCHK    PROBABLE ERROR IN CODING OF ANALYTIC,        
     +       18H HESSIAN FUNCTION./                                     
     +       21H HESCHK      ROW  COL,14X,8HANALYTIC,14X,10H(ESTIMATE)) 
  902 FORMAT(11H HESCHK    ,2I5,2X,E20.13,2X,1H(,E20.13,1H))            
      END                                                               



C  -----------------------
C  |    M C H E P S    |
C  -----------------------        
      SUBROUTINE MCHEPS(EPS)
C
C PURPOSE:
C   COMPUTE MACHINE PRECISION
C
C-------------------------------------------------------------------------
C
C PARAMETERS:
C
C   EPS <-- MACHINE PRECISION
C 
      DOUBLE PRECISION EPS,TEMP,TEMP1
        
        TEMP = 1.D0
 20     CONTINUE
            TEMP = TEMP / 2.D0
            TEMP1 = TEMP + 1.D0
            IF (TEMP1 .NE. 1.D0) GOTO 20
        EPS = TEMP * 2.D0
        RETURN
        END


C
      FUNCTION TWONRM(N,V)
C
C PURPOSE:
C   COMPUTER L-2 NORM
C
C--------------------------------------------------------------------------
C
C PARAMETER:
C
C   N       --> DIMENSION OF PROBLEM
C   V(N)    --> VECTOR WHICH L-2 NORM IS EVALUATED
C
      
      INTEGER N
      DOUBLE PRECISION V(N),TEMP,TWONRM,DDOT
      EXTERNAL DDOT
      INTRINSIC SQRT

      TEMP = DDOT(N,V(1),1,V(1),1)
      TWONRM=SQRT(TEMP)
      RETURN
      END
C  ----------------------
C  |  L N S R C H       |
C  ----------------------
      SUBROUTINE LNSRCH(NR,N,X,F,G,P,XPLS,FPLS,MXTAKE,                  
     +   IRETCD,STEPMX,STEPTL,TYPX,FCN,W2,NFCNT)                              
C     
C     THE ALPHA CONDITION ONLY LINE SEARCH
C
C PURPOSE                                                               
C -------                                                               
C FIND A NEXT NEWTON ITERATE BY LINE SEARCH.                            
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C N            --> DIMENSION OF PROBLEM                                 
C X(N)         --> OLD ITERATE:   X[K-1]                                
C F            --> FUNCTION VALUE AT OLD ITERATE, F(X)                  
C G(N)         --> GRADIENT AT OLD ITERATE, G(X), OR APPROXIMATE        
C P(N)         --> NON-ZERO NEWTON STEP                                 
C XPLS(N)     <--  NEW ITERATE X[K]                                     
C FPLS        <--  FUNCTION VALUE AT NEW ITERATE, F(XPLS)               
C FCN          --> NAME OF SUBROUTINE TO EVALUATE FUNCTION              
C IRETCD      <--  RETURN CODE                                          
C MXTAKE      <--  BOOLEAN FLAG INDICATING STEP OF MAXIMUM LENGTH USED  
C STEPMX       --> MAXIMUM ALLOWABLE STEP SIZE                          
C STEPTL       --> RELATIVE STEP SIZE AT WHICH SUCCESSIVE ITERATES      
C                  CONSIDERED CLOSE ENOUGH TO TERMINATE ALGORITHM       
C TYPX(N)            --> DIAGONAL SCALING MATRIX FOR X (NOT IN UNCMIN)
C IPR          --> DEVICE TO WHICH TO SEND OUTPUT                       
C W2         --> WORKING SPACE
C NFCNT      <--> NUMBER OF FUNCTION EVALUTIONS
C                                                                       
C INTERNAL VARIABLES                                                    
C ------------------                                                    
C SLN              NEWTON LENGTH                                        
C RLN              RELATIVE LENGTH OF NEWTON STEP                       
C                                                                       
      
      INTEGER NR,N,IRETCD,I,K,NFCNT     
      DOUBLE PRECISION STEPMX,STEPTL,TYPX(N),W2(N),X(N),G(N)
      DOUBLE PRECISION XPLS(N),F,FPLS ,P(N)
      DOUBLE PRECISION ALPHA,TMP,SLN,SCL,SLP,DDOT
      DOUBLE PRECISION RLN,TEMP,TEMP1,TEMP2,ALMBDA,T1,T2,T3
      DOUBLE PRECISION ALMBMN,TLMBDA,PLMBDA,PFPLS,DISC,A,B
      LOGICAL MXTAKE                                                    
      EXTERNAL FCN,DSCAL,DDOT
      INTRINSIC ABS,MAX,SQRT
C                                                                       
      MXTAKE=.FALSE.                                                    
      IRETCD=2                                                          
      ALPHA=1D-4
C$    WRITE(IPR,954)                                                    
C$    WRITE(IPR,955) (P(I),I=1,N)                                       
      TMP=0D0                                                           
      DO 5 I=1,N                                                        
       TMP=TMP+P(I)*P(I) 
    5 CONTINUE                                                          
      SLN=SQRT(TMP)                                                     
      IF(SLN.LE.STEPMX) GO TO 10                                        
C                                                                       
C NEWTON STEP LONGER THAN MAXIMUM ALLOWED                               
        SCL=STEPMX/SLN                                                  
        CALL DSCAL(N,SCL,P(1),1)
        SLN=STEPMX                                                      
C$     WRITE(IPR,954)                                                   
C$     WRITE(IPR,955) (P(I),I=1,N)                                      
   10 CONTINUE                                                          
      SLP=DDOT(N,G(1),1,P(1),1)
      RLN=0D0                                                           
      DO 15 I=1,N                                                       
        TEMP=1D0
        TEMP1=ABS(X(I))
        TEMP2=MAX(TEMP1,TEMP)
        TEMP1=ABS(P(I))
        RLN=MAX(RLN,TEMP1/TEMP2)
   15 CONTINUE                                                          
      ALMBMN=STEPTL/RLN                                                 
      ALMBDA=1.0D0                                                      
C$    WRITE(IPR,952) SLN,SLP,RMNLMB,STEPMX,STEPTL                       
C                                                                       
C LOOP                                                                  
C CHECK IF NEW ITERATE SATISFACTORY.  GENERATE NEW LAMBDA IF NECESSARY. 
C                                                                       
  100 CONTINUE                                                          
      IF(IRETCD.LT.2) THEN                                              
        RETURN
      END IF
      DO 105 I=1,N                                                      
        XPLS(I)=X(I) + ALMBDA*P(I)                                      
  105 CONTINUE                                                          
      DO 101 K=1,N
        W2(K)=XPLS(K)*TYPX(K)
101   CONTINUE
      CALL FCN(N,W2,FPLS)
      NFCNT=NFCNT+1
C$    WRITE(IPR,956) ALMBDA                                             
C$    WRITE(IPR,951)                                                    
C$    WRITE(IPR,955) (XPLS(I),I=1,N)                                    
C$    WRITE(IPR,953) FPLS                                               
      IF(FPLS.GT. F+SLP*ALPHA*ALMBDA) GO TO 130                         
C     IF(FPLS.LE. F+SLP*1.E-4*ALMBDA)                                   
C     THEN                                                              
C                                                                       
C SOLUTION FOUND                                                        
C                                                                       
        IRETCD=0                                                        
        IF(ALMBDA.EQ.1D0 .AND. SLN.GT. .99D0*STEPMX) MXTAKE=.TRUE.      
        GO TO 100                                                       
C                                                                       
C SOLUTION NOT (YET) FOUND                                              
C                                                                       
C     ELSE                                                              
  130   IF(ALMBDA .GE. ALMBMN) GO TO 140                                
C       IF(ALMBDA .LT. ALMBMN)                                          
C       THEN                                                            
C                                                                       
C NO SATISFACTORY XPLS FOUND SUFFICIENTLY DISTINCT FROM X               
C                                                                       
          IRETCD=1                                                      
          GO TO 100                                                     
C       ELSE                                                            
C                                                                       
C CALCULATE NEW LAMBDA                                                  
C                                                                       
  140     IF(ALMBDA.NE.1D0) GO TO 150                                   
C         IF(ALMBDA.EQ.1.0)                                             
C         THEN                                                          
C                                                                       
C FIRST BACKTRACK: QUADRATIC FIT                                        
C                                                                       
            TLMBDA=-SLP/(2D0*(FPLS-F-SLP))                              
            GO TO 170                                                   
C         ELSE                                                          
C                                                                       
C ALL SUBSEQUENT BACKTRACKS: CUBIC FIT                                  
C                                                                       
  150       T1=FPLS-F-ALMBDA*SLP                                        
            T2=PFPLS-F-PLMBDA*SLP                                       
            T3=1D0/(ALMBDA-PLMBDA)                                      
            A=T3*(T1/(ALMBDA*ALMBDA) - T2/(PLMBDA*PLMBDA))              
            B=T3*(T2*ALMBDA/(PLMBDA*PLMBDA)                             
     +           - T1*PLMBDA/(ALMBDA*ALMBDA) )                          
            DISC=B*B-3.0*A*SLP                                          
            IF(DISC.LE. B*B) GO TO 160                                  
C           IF(DISC.GT. B*B)                                            
C           THEN                                                        
C                                                                       
C ONLY ONE POSITIVE CRITICAL POINT, MUST BE MINIMUM                     
C                                                                       
              TLMBDA=(-B+SIGN(1.0D0,A)*SQRT(DISC))/(3.0*A)              
              GO TO 165                                                 
C           ELSE                                                        
C                                                                       
C BOTH CRITICAL POINTS POSITIVE, FIRST IS MINIMUM                       
C                                                                       
  160         TLMBDA=(-B-SIGN(1.0D0,A)*SQRT(DISC))/(3.0*A)              
C           ENDIF                                                       
  165       IF(TLMBDA.GT. .5D0*ALMBDA) TLMBDA=.5D0*ALMBDA               
C         ENDIF                                                         
  170     PLMBDA=ALMBDA                                                 
          PFPLS=FPLS                                                    
          IF(TLMBDA.GE. ALMBDA*.1D0) GO TO 180                          
C         IF(TLMBDA.LT.ALMBDA/10.)                                      
C         THEN                                                          
            ALMBDA=ALMBDA*.1                                            
            GO TO 190                                                   
C         ELSE                                                          
  180       ALMBDA=TLMBDA                                               
C         ENDIF                                                         
C       ENDIF                                                           
C     ENDIF                                                             
  190 GO TO 100                                                         
  956 FORMAT(18H LNSRCH    ALMBDA=,E20.13)                              
  951 FORMAT(29H LNSRCH    NEW ITERATE (XPLS))                          
  952 FORMAT(18H LNSRCH    SLN   =,E20.13/                              
     +       18H LNSRCH    SLP   =,E20.13/                              
     +       18H LNSRCH    ALMBMN=,E20.13/                              
     +       18H LNSRCH    STEPMX=,E20.13/                              
     +       18H LNSRCH    STEPTL=,E20.13)                              
  953 FORMAT(19H LNSRCH    F(XPLS)=,E20.13)                             
  954 FORMAT(26H0LNSRCH    NEWTON STEP (P))                             
  955 FORMAT(14H LNSRCH       ,5(E20.13,3X))                            
      END                                                               
C  ----------------------
C  |       Z H Z        |
C  ----------------------     
      SUBROUTINE ZHZ(NR,N,Y,H,U,T)
C
C PURPOSE:
C   COMPUTE QTHQ(N,N) AND ZTHZ(N-1,N-1) = FIRST N-1 ROWS AND 
C   FIRST N-1 COLUMNS OF QTHQ
C
C---------------------------------------------------------------------------
C
C PARAMETERS:
C   
C   NR            --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   Y(N)    --> FIRST BASIS IN Q
C   H(N,N)     <--> ON INPUT : HESSIAN
C               ON OUTPUT: QTHQ (ZTHZ)
C   U(N)       <--  VECTOR TO FORM Q AND Z
C   T(N)        --> WORKSPACE
C
      
      INTEGER NR,N,I,J
      DOUBLE PRECISION T(N),Y(N),H(NR,N),U(N),S,SGN,YNORM
      DOUBLE PRECISION DDOT,D,TEMP1,TEMP2
      EXTERNAL DDOT,DCOPY
      INTRINSIC SQRT,ABS
C
C     U=Y+SGN(Y(N))||Y||E(N)
      IF( Y(N) .NE. 0D0)THEN
        SGN=Y(N)/ABS(Y(N))
      ELSE
        SGN=1D0
      END IF
      YNORM=DDOT(N,Y(1),1,Y(1),1)
      YNORM=SQRT(YNORM)
      U(N)=Y(N)+SGN*YNORM
      CALL DCOPY(N-1,Y(1),1,U(1),1)

C
C     D=UTU/2
      D=DDOT(N,U(1),1,U(1),1)
      D=D/2D0
C
C     T=2HU/UTU
      DO 40 I=1,N
        T(I)=0D0
        DO 30 J=1,N
           T(I)=H(I,J)*U(J)+T(I)
30      CONTINUE
        T(I)=T(I)/D
40    CONTINUE
C
C     S=4UHU/(UTU)**2
      S = DDOT(N,U(1),1,T(1),1)
      S=S/D
C
C     COMPUTE QTHQ (ZTHZ)
      DO 70 I=1,N
        TEMP1=U(I)
        DO 60 J=1,N
          TEMP2=U(J)
          H(I,J)=H(I,J)-U(I)*T(J)-T(I)*U(J)+U(I)*U(J)*S
60      CONTINUE
70    CONTINUE
      RETURN
      END

C  ----------------------
C  |    S O L V E W     |
C  ----------------------
      SUBROUTINE SOLVEW(NR,N,AL,U,W,B)
C
C PURPOSE:
C   SOLVE L*W=ZT*V
C
C----------------------------------------------------------------------
C
C PARAMETERS:
C   NR            --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   AL(N-1,N-1)   --> LOWER TRIAGULAR MATRIX
C   U(N)    --> VECTOR TO FORM Z
C   W(N)    --> ON INPUT : VECTOR V IN SYSTEM OF LINEAR EQUATIONS
C               ON OUTPUT: SOLUTION OF SYSTEM OF LINEAR EQUATIONS
C   B(N)    --> WORKSPACE TO STORE ZT*V
      
      INTEGER NR,N,I,J
      DOUBLE PRECISION B(N),AL(NR,1),W(N),U(N),D,DDOT
      EXTERNAL DDOT
C
C     FORM ZT*V (STORED IN B)
	  D = DDOT(N,U(1),1,U(1),1)
      D=D/2D0
      DO 20 I=1,N-1
        B(I)=0D0
        DO 15 J=1,N
          B(I)=B(I)+U(J)*U(I)*W(J)/D
15      CONTINUE
        B(I)=W(I)-B(I)
20    CONTINUE
C
C     SOLVE LW=ZT*V
	  CALL FORSLV(NR,N-1,AL,W,B)
	  RETURN
      END

C  ----------------------
C  |     D S T A R      |
C  ----------------------
      SUBROUTINE DSTAR(NR,N,U,S,W1,W2,W3,SIGMA,AL,D)
C
C PURPOSE:
C   COMPUTE TENSOR STEP D=SIGMA*S+ZT*T(SIGMA)
C
C------------------------------------------------------------------------
C
C PARAMETERS:
C   NR            --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   U(N)    --> VECTOR TO FORM Z
C   S(N)    --> PREVIOUS STEP
C   W1(N)   --> L**-1*ZT*A, WHERE A IS DESCRIBED IN SUBROUTINE SLVMDL
C   W2(N)   --> L**-1*ZT*SH, WHERE H IS CURRENT HESSIAN
C   W3(N)   --> L**-1*ZT*G, WHERE G IS CURRENT GRADIENT
C   SIGMA   --> SOLUTION FOR REDUCED ONE VARIABLE MODEL
C   AL(N-1,N-1) --> LOWER TRIANGULAR MATRIX L
C   D(N)    --> TENSOR STEP
C
      
      INTEGER NR,N,I
      DOUBLE PRECISION U(N),S(N),W1(N-1),W2(N-1),W3(N-1),AL(NR,1),D(N)
      DOUBLE PRECISION SIGMA,DDOT,UTU,TEMP,UTT
      EXTERNAL DDOT
      IF (N.EQ.1) THEN
        D(1)=SIGMA * S(1)
      ELSE
C
C     COMPUTE T(SIGMA)=-(ZTHZ)*ZT*(G+SIGMA*SH+SIGMA**2*A/2) (STORED IN D)
      DO 10 I=1,N-1
        W2(I)=W3(I)+SIGMA*W2(I)+0.5D0*W1(I)*SIGMA*SIGMA
10    CONTINUE
	
      CALL BAKSLV(NR,N-1,AL,D,W2)
	
      D(N)=0D0
C
C     COMPUTE TENSOR STEP D=SIGMA*S+ZT*T(SIGMA)
      UTU=DDOT(N,U(1),1,U(1),1)
      UTT=DDOT(N,U(1),1,D(1),1)
      TEMP=UTT/UTU
      DO 50 I=1,N
        D(I)=SIGMA*S(I)-(D(I)-2D0*U(I)*TEMP)
50    CONTINUE
      END IF
      RETURN
      END

C  ----------------------
C  |     M K M D L      |
C  ----------------------     
      SUBROUTINE MKMDL(NR,N,F,FP,G,GP,S,H,ALPHA,BETA,SH,A)
C
C PURPOSE:
C   FORM TENSOR MODEL
C
C-----------------------------------------------------------------------
C
C PARAMETERS:
C   NR            --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   F       --> CURRENT FUNCTION VALUE
C   FP            --> PREVIOUS FUNCTION VALUE
C   G(N)    --> CURRENT GRADIENT
C   GP(N)   --> PREVIOUS GRADIENT
C   S(N)    --> STEP TO PREVIOUS POINT
C   H(N,N)  --> HESSIAN
C   ALPHA      <--  SCALAR TO FORM 3RD ORDER TERM OF TENSOR MODEL
C   BETA       <--  SCALAR TO FORM 4TH ORDER TERM OF TENSOR MODEL
C   SH(N)      <--  SH
C   A(N)       <--  A=2*(GP-G-SH-S*BETA/(6*STS))
C
      
      INTEGER NR,N,I,J
      DOUBLE PRECISION F,FP,G(N),GP(N),S(N),H(NR,N),SH(N),A(N)
      DOUBLE PRECISION ALPHA,BETA,DDOT,GS,GPS,SHS,B1,B2,STS
      EXTERNAL DDOT
C
C     COMPUTE SH
      DO 20 I=1,N
        SH(I)=0D0
        DO 10 J=1,N
          SH(I)=SH(I)+S(J)*H(J,I)
10      CONTINUE
20    CONTINUE

      GS=DDOT(N,G(1),1,S(1),1)
      GPS=DDOT(N,GP(1),1,S(1),1)
      SHS=DDOT(N,SH(1),1,S(1),1)
      B1=GPS-GS-SHS
      B2=FP-F-GS-.5D0*SHS
      ALPHA=24D0*B2-6D0*B1
      BETA=24D0*B1-72D0*B2
C
C     COMPUTE A
      STS=DDOT(N,S(1),1,S(1),1)
      DO 50 I=1,N
        A(I)=2D0*(GP(I)-G(I)-SH(I)-S(I)*BETA/(6D0*STS))
50    CONTINUE
      RETURN
      END


C  ----------------------
C  |     S I G M A      |
C  ----------------------
      SUBROUTINE SIGMA(SGSTAR,A,B,C,D)
C
C PURPOSE:
C   COMPUTE DESIRABLE ROOT OF REDUCED ONE VARIABLE EQUATION
C
C-------------------------------------------------------------------------
C
C PARAMETERS:
C   SGSTAR     --> DESIRABLE ROOT
C   A       --> COEFFICIENT OF 3RD ORDER TERM
C   B       --> COEFFICIENT OF 2ND ORDER TERM
C   C       --> COEFFICIENT OF 1ST ORDER TERM
C   D       --> COEFFICIENT OF CONSTANT TERM
C
      DOUBLE PRECISION SGSTAR,A,B,C,D
      DOUBLE PRECISION S1,S2,S3      
C
C     COMPUTE ALL THREE ROOTS
      CALL ROOTS(S1,S2,S3,A,B,C,D)
C
C     SORT ROOTS
      CALL SORTRT(S1,S2,S3)
C
C     CHOOSE DESIRABLE ROOT
      IF( A .GT. 0D0 )THEN
        SGSTAR=S3
        IF( S2 .GE. 0D0 )THEN
          SGSTAR=S1
        END IF
      ELSE
C       IF  A  <  0  THEN
        SGSTAR=S2
        IF( (S1.GT.0D0) .OR. (S3.LT.0D0) )THEN
          IF( S1 .GT. 0D0)THEN
            SGSTAR=S1
          ELSE
            SGSTAR=S3
          END IF
          A=0D0
        END IF
      END IF
      RETURN
      END

C  ----------------------
C  |     R O O T S      |
C  ----------------------     
      SUBROUTINE ROOTS(S1,S2,S3,A,B,C,D)
C
C PURPOSE:
C   COMPUTE ROOT(S) OF 3RD ORDER EQUATION
C
C---------------------------------------------------------------------------
C
C PARAMETERS:
C   S1             <--  ROOT   (IF THREE ROOTS ARE
C   S2             <--  ROOT    EQUAL, THEN S1=S2=S3)
C   S3             <--  ROOT    
C   A       --> COEFFICIENT OF 3RD ORDER TERM
C   B       --> COEFFICIENT OF 2ND ORDER TERM
C   C       --> COEFFICIENT OF 1ST ORDER TERM
C   D       --> COEFFICIENT OF CONSTANT TERM
      DOUBLE PRECISION S1,S2,S3,A,B,C,D
      DOUBLE PRECISION PI,A1,A2,A3,Q,R,V,S,T,TEMP,THETA
      
      INTRINSIC ACOS, COS, SQRT
C
C     SET VALUE OF PI
      PI=3.141592653589793D0
      A1=B/A
      A2=C/A
      A3=D/A
      Q=(.3D01*A2-A1*A1)/.9D01
      R=(.9D01*A1*A2-.27D02*A3-.2D01*A1*A1*A1)/.54D02
      V=Q*Q*Q+R*R
      IF(V .GT. 0D0)THEN
        S=R+SQRT(V)
        T=R-SQRT(V)
        IF(T .LT. 0D0)THEN
          T=-(-T)**(1D0/3D0)  
        ELSE
          T=T**(1D0/3D0)
        END IF
        IF(S .LT. 0)THEN
          S=-(-S)**(1D0/3D0)
        ELSE
          S=S**(1D0/3D0)
        END IF
        S1=S+T-A1/3D0
        S3=S1
        S2=S1
      ELSE    
        TEMP=R/SQRT(-Q**.3D01)
        THETA=ACOS(TEMP)
        THETA=THETA/.3D01
        TEMP=.2D01*SQRT(-Q)
        S1=TEMP*COS(THETA)-A1/.3D01
        S2=TEMP*COS(THETA+PI*.2D01/.3D01)-A1/.3D01
        S3=TEMP*COS(THETA+PI*.4D01/.3D01)-A1/.3D01
      END IF
      RETURN
      END

C  ----------------------
C  | S O R T R T         |
C  ----------------------
      SUBROUTINE SORTRT(S1,S2,S3)
C 
C PURPOSE:
C   SORT ROOTS INTO ASCENDING ORDER
C
C-----------------------------------------------------------------------------
C
C PARAMETERS:
C   S1             <--> ROOT
C   S2             <--> ROOT
C   S3             <--> ROOT
C
      DOUBLE PRECISION S1,S2,S3
      DOUBLE PRECISION T
      
      
      IF(S1 .GT. S2)THEN
        T=S1
        S1=S2
        S2=T
      END IF
      IF(S2 .GT. S3)THEN
        T=S2
        S2=S3
        S3=T
      END IF
      IF(S1 .GT. S2)THEN
        T=S1
        S1=S2
        S2=T
      END IF
      RETURN
      END
C  ----------------------
C  |  F S T O F D       |
C  ----------------------
      SUBROUTINE FSTOFD(NR,M,N,XPLS,FCN,FPLS,A,TYPX,RNOISE,
     Z                  FHAT,ICASE,NFCNT)
C PURPOSE                                                               
C -------                                                               
C FIND FIRST ORDER FORWARD FINITE DIFFERENCE APPROXIMATION "A" TO THE   
C FIRST DERIVATIVE OF THE FUNCTION DEFINED BY THE SUBPROGRAM "FNAME"    
C EVALUATED AT THE NEW ITERATE "XPLS".                                  
C                                                                       
C                                                                       
C FOR OPTIMIZATION USE THIS ROUTINE TO ESTIMATE:                        
C 1) THE FIRST DERIVATIVE (GRADIENT) OF THE OPTIMIZATION FUNCTION "FCN  
C    ANALYTIC USER ROUTINE HAS BEEN SUPPLIED;                           
C 2) THE SECOND DERIVATIVE (HESSIAN) OF THE OPTIMIZATION FUNCTION       
C    IF NO ANALYTIC USER ROUTINE HAS BEEN SUPPLIED FOR THE HESSIAN BUT  
C    ONE HAS BEEN SUPPLIED FOR THE GRADIENT ("FCN") AND IF THE          
C    OPTIMIZATION FUNCTION IS INEXPENSIVE TO EVALUATE                   
C                                                                       
C NOTE                                                                  
C ----                                                                  
C _M=1 (OPTIMIZATION) ALGORITHM ESTIMATES THE GRADIENT OF THE FUNCTION  
C      (FCN).   FCN(X) # F: R(N)-->R(1)                                 
C _M=N (SYSTEMS) ALGORITHM ESTIMATES THE JACOBIAN OF THE FUNCTION       
C      FCN(X) # F: R(N)-->R(N).                                         
C _M=N (OPTIMIZATION) ALGORITHM ESTIMATES THE HESSIAN OF THE OPTIMIZATIO
C      FUNCTION, WHERE THE HESSIAN IS THE FIRST DERIVATIVE OF "FCN"     
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C NR           --> ROW DIMENSION OF MATRIX                              
C M            --> NUMBER OF ROWS IN A                                  
C N            --> NUMBER OF COLUMNS IN A; DIMENSION OF PROBLEM         
C XPLS(N)      --> NEW ITERATE:  X[K]                                   
C FCN          --> NAME OF SUBROUTINE TO EVALUATE FUNCTION              
C FPLS(M)      --> _M=1 (OPTIMIZATION) FUNCTION VALUE AT NEW ITERATE:   
C                       FCN(XPLS)                                       
C                  _M=N (OPTIMIZATION) VALUE OF FIRST DERIVATIVE        
C                       (GRADIENT) GIVEN BY USER FUNCTION FCN           
C                  _M=N (SYSTEMS)  FUNCTION VALUE OF ASSOCIATED         
C                       MINIMIZATION FUNCTION                           
C A(NR,N)     <--  FINITE DIFFERENCE APPROXIMATION (SEE NOTE).  ONLY
C                  LOWER TRIANGULAR MATRIX AND DIAGONAL ARE RETURNED    
C RNOISE       --> RELATIVE NOISE IN FCN [F(X)]                         
C FHAT(M)      --> WORKSPACE                                            
C ICASE        --> =1 OPTIMIZATION (GRADIENT)                           
C                  =2 SYSTEMS                                           
C                  =3 OPTIMIZATION (HESSIAN) 
C NFCNT       <--> NUMBER OF FUNCTION EVALUTIONS                           
C                                                                       
C INTERNAL VARIABLES                                                    
C ------------------                                                    
C STEPSZ - STEPSIZE IN THE J-TH VARIABLE DIRECTION                      
C                                                                       
     
      INTEGER NR,M,N,ICASE,NFCNT 
      DOUBLE PRECISION XPLS(N),FPLS(M),FHAT(M),TYPX(N),A(NR,N)  
      DOUBLE PRECISION RNOISE
      INTEGER I,J,NM1,JP1
      DOUBLE PRECISION XTMPJ,STEPSZ                                               
      EXTERNAL FCN
      INTRINSIC ABS, MAX, SQRT
C                                                                       
C FIND J-TH COLUMN OF A                                                 
C EACH COLUMN IS DERIVATIVE OF F(FCN) WITH RESPECT TO XPLS(J)           
C                                                                       
      DO 30 J=1,N                                                       
        XTMPJ=XPLS(J)                                                   
        STEPSZ=SQRT(RNOISE)*MAX(ABS(XPLS(J)),1.D0)                        
        XPLS(J)=XTMPJ+STEPSZ                                            
        CALL FCN(N,XPLS,FHAT) 
        NFCNT = NFCNT + 1                                          
        XPLS(J)=XTMPJ                                                   
        DO 20 I=1,M                                                     
          A(I,J)=(FHAT(I)-FPLS(I))/STEPSZ                               
          A(I,J)=A(I,J)*TYPX(J)
   20   CONTINUE                                                        
   30 CONTINUE                                                          
      IF(ICASE.NE.3) RETURN                                             
C                                                                       
C IF COMPUTING HESSIAN, A MUST BE SYMMETRIC                             
C                                                                       
      IF(N.EQ.1) RETURN                                                 
      NM1=N-1                                                           
      DO 50 J=1,NM1                                                     
        JP1=J+1                                                         
        DO 40 I=JP1,M                                                   
          A(I,J)=(A(I,J)+A(J,I))/2.0                                    
   40   CONTINUE                                                        
   50 CONTINUE                                                          
      RETURN                                                            
      END                                                               
C  ----------------------
C  |  S N D O F D       |
C  ----------------------
      SUBROUTINE SNDOFD(NR,N,XPLS,FCN,FPLS,A,TYPX,
     Z                    RNOISE,STEPSZ,ANBR,NFCNT)       
C PURPOSE                                                               
C -------                                                               
C FIND SECOND ORDER FORWARD FINITE DIFFERENCE APPROXIMATION "A"         
C TO THE SECOND DERIVATIVE (HESSIAN) OF THE FUNCTION DEFINED BY THE SUBP
C "FCN" EVALUATED AT THE NEW ITERATE "XPLS"                             
C                                                                       
C FOR OPTIMIZATION USE THIS ROUTINE TO ESTIMATE                         
C 1) THE SECOND DERIVATIVE (HESSIAN) OF THE OPTIMIZATION FUNCTION       
C    IF NO ANALYTICAL USER FUNCTION HAS BEEN SUPPLIED FOR EITHER        
C    THE GRADIENT OR THE HESSIAN AND IF THE OPTIMIZATION FUNCTION       
C    "FCN" IS INEXPENSIVE TO EVALUATE.                                  
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C NR           --> ROW DIMENSION OF MATRIX                              
C N            --> DIMENSION OF PROBLEM                                 
C XPLS(N)      --> NEW ITERATE:   X[K]                                  
C FCN          --> NAME OF SUBROUTINE TO EVALUATE FUNCTION              
C FPLS         --> FUNCTION VALUE AT NEW ITERATE, F(XPLS)               
C A(N,N)      <--  FINITE DIFFERENCE APPROXIMATION TO HESSIAN           
C                  ONLY LOWER TRIANGULAR MATRIX AND DIAGONAL            
C                  ARE RETURNED                                         
C RNOISE       --> RELATIVE NOISE IN FNAME [F(X)]                       
C STEPSZ(N)    --> WORKSPACE (STEPSIZE IN I-TH COMPONENT DIRECTION)     
C ANBR(N)      --> WORKSPACE (NEIGHBOR IN I-TH DIRECTION)
C NFCNT       <--> NUMBER OF FUNCTION EVALUATIONS              
C                                                                       
C    
      INTEGER NR,N,NFCNT
      DOUBLE PRECISION XPLS(N),TYPX(N),STEPSZ(N),ANBR(N),A(NR,N) 
      DOUBLE PRECISION FPLS,RNOISE,OV3,XTMPI,XTMPJ,FHAT
      INTEGER I,J,IP1
      EXTERNAL FCN
      INTRINSIC ABS, MAX
C                                                                       
C FIND I-TH STEPSIZE AND EVALUATE NEIGHBOR IN DIRECTION                 
C OF I-TH UNIT VECTOR.                                                  
C                                                                       
      OV3 = 1D0/3D0
      DO 10 I=1,N                                                       
        XTMPI=XPLS(I)                                                   
        STEPSZ(I)=RNOISE**OV3 * MAX(ABS(XPLS(I)),1D0)                   
        XPLS(I)=XTMPI+STEPSZ(I)                                         
        CALL FCN(N,XPLS,ANBR(I))
        NFCNT = NFCNT + 1                                      
        XPLS(I)=XTMPI                                                   
   10 CONTINUE                                                          
C                                                                       
C CALCULATE COLUMN I OF A                                               
C                                                                       
      DO 30 I=1,N                                                       
        XTMPI=XPLS(I)                                                   
        XPLS(I)=XTMPI+2.0*STEPSZ(I)                                     
        CALL FCN(N,XPLS,FHAT) 
        NFCNT = NFCNT + 1                                          
        A(I,I)=((FPLS-ANBR(I))+(FHAT-ANBR(I)))/(STEPSZ(I)*STEPSZ(I))    
        A(I,I)=A(I,I)*(TYPX(I)*TYPX(I))
C                                                                       
C CALCULATE SUB-DIAGONAL ELEMENTS OF COLUMN                             
        IF(I.EQ.N) GO TO 25                                             
        XPLS(I)=XTMPI+STEPSZ(I)                                         
        IP1=I+1                                                         
        DO 20 J=IP1,N                                                   
          XTMPJ=XPLS(J)                                                 
          XPLS(J)=XTMPJ+STEPSZ(J)                                       
          CALL FCN(N,XPLS,FHAT) 
          NFCNT = NFCNT + 1                                       
          A(J,I)=((FPLS-ANBR(I))+(FHAT-ANBR(J)))/(STEPSZ(I)*STEPSZ(J))  
          A(J,I)=A(J,I)*(TYPX(I)*TYPX(J))
          XPLS(J)=XTMPJ                                                 
   20   CONTINUE                                                        
   25   XPLS(I)=XTMPI                                                   
   30 CONTINUE                                                          
      RETURN                                                            
      END                                                               
C  ----------------------
C  |  B A K S L V       |
C  ----------------------
      SUBROUTINE BAKSLV(NR,N,A,X,B)                                     
C                                                                       
C PURPOSE                                                               
C -------                                                               
C SOLVE  AX=B  WHERE A IS UPPER TRIANGULAR MATRIX.                      
C NOTE THAT A IS INPUT AS A LOWER TRIANGULAR MATRIX AND                 
C THAT THIS ROUTINE TAKES ITS TRANSPOSE IMPLICITLY.                     
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C NR           --> ROW DIMENSION OF MATRIX                              
C N            --> DIMENSION OF PROBLEM                                 
C A(N,N)       --> LOWER TRIANGULAR MATRIX (PRESERVED)                  
C X(N)        <--  SOLUTION VECTOR                                      
C B(N)         --> RIGHT-HAND SIDE VECTOR                               
C                                                                       
C NOTE                                                                  
C ----                                                                  
C IF B IS NO LONGER REQUIRED BY CALLING ROUTINE,                        
C THEN VECTORS B AND X MAY SHARE THE SAME STORAGE.                      
C                                                                       
      INTEGER NR,N
      DOUBLE PRECISION A(NR,N),X(N),B(N)  
      INTEGER I,IP1,J
      DOUBLE PRECISION SUM                                    
C                                                                       
C SOLVE (L-TRANSPOSE)X=B. (BACK SOLVE)                                  
C                                                                       
      I=N                                                               
      X(I)=B(I)/A(I,I)                                                  
      IF(N.EQ.1) RETURN                                                 
   30 IP1=I                                                             
      I=I-1                                                             
      SUM=0.                                                            
      DO 40 J=IP1,N                                                     
        SUM=SUM+A(J,I)*X(J)                                             
   40 CONTINUE                                                          
      X(I)=(B(I)-SUM)/A(I,I)                                            
      IF(I.GT.1) GO TO 30                                               
      RETURN                                                            
      END                                                               
C  ----------------------
C  |  F O R S L V       |
C  ----------------------
       SUBROUTINE FORSLV (NR,N,A,X,B)                                   
C                                                                       
C PURPOSE                                                               
C --------                                                              
C SOLVE  AX=B  WHERE A  IS LOWER TRIANGULAR  MATRIX                     
C                                                                       
C PARAMETERS                                                            
C ---------                                                             
C                                                                       
C NR            -----> ROW DIMENSION OF MATRIX                          
C N             -----> DIMENSION OF PROBLEM                             
C A(N,N)        -----> LOWER TRIANGULAR MATRIX (PRESERVED)              
C X(N)          <----  SOLUTION VECTOR                                   
C B(N)           ----> RIGHT-HAND SIDE VECTOR                           
C                                                                       
C NOTE                                                                  
C-----                                                                  
C THEN VECTORS B AND X MAY SHARE THE SAME STORAGE                       
C                                                                       
      INTEGER NR,N
      DOUBLE PRECISION A(NR,N),X(N),B(N)
      INTEGER I,J,IM1
      DOUBLE PRECISION SUM                                       
C                                                                       
C SOLVE LX=B.  (FOREWARD  SOLVE)                                        
C                                                                       
      X(1)=B(1)/A(1,1)                                                  
      IF(N.EQ.1) RETURN                                                 
      DO 20 I=2,N                                                       
        SUM=0.0                                                         
        IM1=I-1                                                         
        DO 10 J=1,IM1                                                   
          SUM=SUM+A(I,J)*X(J)                                           
   10   CONTINUE                                                        
        X(I)=(B(I)-SUM)/A(I,I)                                          
   20 CONTINUE                                                          
      RETURN                                                            
      END
C  ----------------------
C  |  C H O L D R       |
C  ----------------------
      SUBROUTINE CHOLDR(NR,N,H,G,EPS,PIVOT,E,DIAG,ADDMAX)
C
C PURPOSE:
C   DRIVER FOR CHOLESKY DECOMPOSITION
C
C----------------------------------------------------------------------
C
C PARAMETERS:
C
C   NR            --> ROW DIMENSION
C   N       --> DIMENSION OF PROBLEM
C   H(N,N)  --> MATRIX
C   G(N)    --> WORK SPACE
C   EPS           --> MACHINE EPSILON
C   PIVOT(N)      --> PIVOTING VECTOR
C   E(N)    --> DIAGONAL MATRIX ADDED TO H FOR MAKING H P.D.
C   DIAG(N) --> DIAGONAL OF H
C   ADDMAX  --> ADDMAX * I  IS ADDED TO H

      INTEGER NR,N
      DOUBLE PRECISION H(NR,N),G(N),EPS,E(N),DIAG(N),
     Z      ADDMAX,TEMP
      INTEGER PIVOT(N),I,J,K
      LOGICAL REDO
      DOUBLE PRECISION TAU1,TAU2
      INTRINSIC SQRT

      REDO=.FALSE.
C
C     SAVE DIAGONAL OF H
      DO 10 I=1,N
        DIAG(I)=H(I,I)
10    CONTINUE
      TAU1=EPS**(1D0/3D0)
      TAU2=TAU1
      CALL MODCHL(NR,N,H,G,EPS,TAU1,TAU2,PIVOT,E)
      ADDMAX=E(N)
      DO 22 I=1,N
        IF(PIVOT(I) .NE. I)REDO=.TRUE.
22    CONTINUE
      IF((ADDMAX .GT. 0D0) .OR. REDO)THEN
C********************************
C                       *
C       H IS NOT P.D.         *
C                       *
C********************************
C
C     H=H+UI
        DO 30 I=2,N
          DO 32 J=1,I-1
            H(I,J)=H(J,I)
32        CONTINUE
30      CONTINUE
        DO 34 I=1,N
          PIVOT(I)=I
          H(I,I)=DIAG(I)+ADDMAX
34      CONTINUE
C********************************
C                       *
C        COMPUTE L            *
C                       *
C********************************
        DO 40 J=1,N
C
C     COMPUTE L(J,J)
          TEMP=0D0
          IF(J .GT. 1)THEN
            DO 41 I=1,J-1
              TEMP=TEMP+H(J,I)*H(J,I)
41          CONTINUE
          END IF
          H(J,J)=H(J,J)-TEMP
          H(J,J)=SQRT(H(J,J))
C
C     COMPUTE L(I,J)
          DO 43 I=J+1,N
            TEMP=0D0
            IF(J .GT. 1)THEN
              DO 45 K=1,J-1
                TEMP=TEMP+H(I,K)*H(J,K)
45            CONTINUE
            END IF
            H(I,J)=H(J,I)-TEMP
            H(I,J)=H(I,J)/H(J,J)
43        CONTINUE
40      CONTINUE
      END IF
      RETURN
      END
C  ----------------------
C  |  M O D C H L       |
C  ----------------------
C*********************************************************************
C       
C       SUBROUTINE NAME: MODCHL
C
C       AUTHORS :  ELIZABETH ESKOW AND ROBERT B. SCHNABEL
C
C       DATE    : DECEMBER, 1988
C
C       PURPOSE : PERFORM A MODIFIED CHOLESKY FACTORIZATION
C                 OF THE FORM (PTRANSPOSE)AP  + E = L(LTRANSPOSE), 
C       WHERE L IS STORED IN THE LOWER TRIANGLE OF THE 
C       ORIGINAL MATRIX A.
C       THE FACTORIZATION HAS 2 PHASES: 
C        PHASE 1: PIVOT ON THE MAXIMUM DIAGONAL ELEMENT.
C            CHECK THAT THE NORMAL CHOLESKY UPDATE 
C            WOULD RESULT IN A POSITIVE DIAGONAL 
C            AT THE CURRENT ITERATION, AND
C            IF SO, DO THE NORMAL CHOLESKY UPDATE,
C            OTHERWISE SWITCH TO PHASE 2.
C        PHASE 2: PIVOT ON THE MINIMUM OF THE NEGATIVES
C            OF THE LOWER GERSCHGORIN BOUND 
C            ESTIMATES.
C            COMPUTE THE AMOUNT TO ADD TO THE 
C            PIVOT ELEMENT AND ADD THIS 
C            TO THE PIVOT ELEMENT.
C            DO THE CHOLESKY UPDATE.
C            UPDATE THE ESTIMATES OF THE 
C            GERSCHGORIN BOUNDS.
C
C       INPUT   : NDIM    - LARGEST DIMENSION OF MATRIX THAT 
C                           WILL BE USED
C
C                 N       - DIMENSION OF MATRIX A
C
C                 A       - N*N SYMMETRIC MATRIX (ONLY LOWER TRIANGULAR
C            PORTION OF A, INCLUDING THE MAIN DIAGONAL, IS USED)
C
C                 G       - N*1 WORK ARRAY
C
C                 MCHEPS - MACHINE PRECISION
C
C                TAU1    - TOLERANCE USED FOR DETERMINING WHEN TO SWITCH TO 
C                          PHASE 2
C
C                TAU2    - TOLERANCE USED FOR DETERMINING THE MAXIMUM
C                          CONDITION NUMBER OF THE FINAL 2X2 SUBMATRIX.
C
C
C       OUTPUT  : L     - STORED IN THE MATRIX A (IN LOWER TRIANGULAR
C                           PORTION OF A, INCLUDING THE MAIN DIAGONAL)
C
C                 P     - A RECORD OF HOW THE ROWS AND COLUMNS
C                         OF THE MATRIX WERE PERMUTED WHILE
C                         PERFORMING THE DECOMPOSITION
C
C                 E     - N*1 ARRAY, THE ITH ELEMENT IS THE 
C                         AMOUNT ADDED TO THE DIAGONAL OF A 
C                         AT THE ITH ITERATION
C
C
C************************************************************************
      SUBROUTINE MODCHL(NDIM,N,A,G,MCHEPS,TAU1,TAU2,P,E)
   
      INTEGER N,NDIM
      DOUBLE PRECISION A(NDIM,N),G(N),MCHEPS,TAU1,TAU2
      INTEGER P(N)
      DOUBLE PRECISION E(N)
   
C
C  J        - CURRENT ITERATION NUMBER
C  IMING    - INDEX OF THE ROW WITH THE MIN. OF THE 
C           NEG. LOWER GERSCH. BOUNDS
C  IMAXD    - INDEX OF THE ROW WITH THE MAXIMUM DIAG. 
C           ELEMENT
C  I,ITEMP,JPL,K  - TEMPORARY INTEGER VARIABLES
C  DELTA    - AMOUNT TO ADD TO AJJ AT THE JTH ITERATION
C  GAMMA    - THE MAXIMUM DIAGONAL ELEMENT OF THE ORIGINAL
C           MATRIX A.
C  NORMJ    - THE 1 NORM OF A(COLJ), ROWS J+1 --> N.
C  MING     - THE MINIMUM OF THE NEG. LOWER GERSCH. BOUNDS
C  MAXD     - THE MAXIMUM DIAGONAL ELEMENT
C  TAUGAM - TAU1 * GAMMA
C  PHASE1      - LOGICAL, TRUE IF IN PHASE1, OTHERWISE FALSE
C  DELTA1,TEMP,JDMIN,TDMIN,TEMPJJ - TEMPORARY DOUBLE PRECISION VARS.
C

      INTEGER J,IMING,I,IMAXD,ITEMP,JP1,K
      DOUBLE PRECISION DELTA,GAMMA
      DOUBLE PRECISION NORMJ, MING,MAXD
      DOUBLE PRECISION DELTA1,TEMP,JDMIN,TDMIN,TAUGAM,TEMPJJ
      LOGICAL PHASE1
      INTRINSIC ABS, MAX, SQRT, MIN
   
      CALL INIT(N, NDIM, A, PHASE1, DELTA, P, G, E,
     *         MING,TAU1,GAMMA,TAUGAM)
C     CHECK FOR N=1
      IF (N.EQ.1) THEN
         DELTA = (TAU2 * ABS(A(1,1))) - A(1,1)
         IF (DELTA .GT. 0) E(1)=DELTA
         IF (A(1,1) .EQ. 0) E(1) = TAU2
         A(1,1)=SQRT(A(1,1)+E(1))
      ENDIF 
C
C  
      DO 200 J = 1, N-1
C
C        PHASE 1
C
         IF ( PHASE1 ) THEN
C         
C           FIND INDEX OF MAXIMUM DIAGONAL ELEMENT A(I,I) WHERE I>=J
C
            MAXD = A(J,J)
            IMAXD = J
            DO 20 I = J+1, N
               IF (MAXD .LT. A(I,I)) THEN
                  MAXD = A(I,I)
                  IMAXD = I
               END IF
 20         CONTINUE

C
C           PIVOT TO THE TOP THE ROW AND COLUMN WITH THE MAX DIAG
C
            IF (IMAXD .NE. J) THEN
C
C              SWAP ROW J WITH ROW OF MAX DIAG
C
               DO 30 I = 1, J-1
                  TEMP = A(J,I)
                  A(J,I) = A(IMAXD,I)
                  A(IMAXD,I) = TEMP
 30            CONTINUE
C
C              SWAP COLJ AND ROW MAXDIAG BETWEEN J AND MAXDIAG
C
               DO 35 I = J+1,IMAXD-1
                  TEMP = A(I,J)
                  A(I,J) = A(IMAXD,I)
                  A(IMAXD,I) = TEMP
 35            CONTINUE
C
C              SWAP COLUMN J WITH COLUMN OF MAX DIAG
C
               DO 40 I = IMAXD+1, N
                  TEMP = A(I,J)
                  A(I,J) = A(I,IMAXD)
                  A(I,IMAXD) = TEMP
 40            CONTINUE
C
C              SWAP DIAG ELEMENTS
C        
               TEMP = A(J,J)
               A(J,J) = A(IMAXD,IMAXD)
               A(IMAXD,IMAXD) = TEMP
C
C              SWAP ELEMENTS OF THE PERMUTATION VECTOR
C
               ITEMP = P(J)
               P(J) = P(IMAXD)
               P(IMAXD) = ITEMP

            END IF


C           CHECK TO SEE WHETHER THE NORMAL CHOLESKY UPDATE FOR THIS 
C           ITERATION WOULD RESULT IN A POSITIVE DIAGONAL, 
C           AND IF NOT THEN SWITCH TO PHASE 2.

            JP1 = J+1
            TEMPJJ=A(J,J)

            IF (TEMPJJ.GT.0) THEN

               JDMIN=A(JP1,JP1)
               DO 60 I = JP1, N
                  TEMP = A(I,J) * A(I,J) / TEMPJJ
                  TDMIN = A(I,I) - TEMP
                  JDMIN = MIN(JDMIN, TDMIN)
 60            CONTINUE  

               IF (JDMIN .LT. TAUGAM) PHASE1 = .FALSE.

            ELSE

               PHASE1 = .FALSE.

            END IF

            IF (PHASE1) THEN
C
C              DO THE NORMAL CHOLESKY UPDATE IF STILL IN PHASE 1
C
               A(J,J) = SQRT(A(J,J))
               TEMPJJ = A(J,J)
               DO 70 I = JP1, N
                  A(I,J) = A(I,J) / TEMPJJ
 70            CONTINUE
               DO 80 I=JP1,N
                  TEMP=A(I,J)
                  DO 75 K = JP1, I
                     A(I,K) = A(I,K) - (TEMP * A(K,J))
 75               CONTINUE
 80            CONTINUE

               IF (J .EQ. N-1) A(N,N)=SQRT(A(N,N))

            ELSE

C
C              CALCULATE THE NEGATIVES OF THE LOWER GERSCHGORIN BOUNDS
C
               CALL GERSCH(NDIM,N,A,J,G)

            END IF         

         END IF


C
C        PHASE 2
C
         IF (.NOT. PHASE1) THEN

            IF (J .NE. N-1) THEN
C
C              FIND THE MINIMUM NEGATIVE GERSHGORIN BOUND
C

               IMING=J
               MING = G(J)
               DO 90 I = J+1,N
                  IF (MING .GT. G(I)) THEN
                     MING = G(I)
                     IMING = I   
                  END IF
 90            CONTINUE
   
C
C               PIVOT TO THE TOP THE ROW AND COLUMN WITH THE 
C               MINIMUM NEGATIVE GERSCHGORIN BOUND
C
                IF (IMING .NE. J) THEN
C 
C                  SWAP ROW J WITH ROW OF MIN GERSCH BOUND
C 
                   DO 100 I = 1, J-1
                      TEMP = A(J,I)
                       A(J,I) = A(IMING,I)
                       A(IMING,I) = TEMP
 100               CONTINUE
C
C                  SWAP COLJ WITH ROW IMING FROM J TO IMING
C
                   DO 105 I = J+1,IMING-1
                      TEMP = A(I,J)
                      A(I,J) = A(IMING,I)
                      A(IMING,I) = TEMP
 105              CONTINUE
C 
C                 SWAP COLUMN J WITH COLUMN OF MIN GERSCH BOUND
C         
                  DO 110 I = IMING+1, N
                     TEMP = A(I,J)
                     A(I,J) = A(I,IMING)
                     A(I,IMING) = TEMP
 110              CONTINUE
C
C                 SWAP DIAGONAL ELEMENTS
C
                  TEMP = A(J,J)
                  A(J,J) = A(IMING,IMING)
                  A(IMING,IMING) = TEMP
C 
C                 SWAP ELEMENTS OF THE PERMUTATION VECTOR
C    
                  ITEMP = P(J)
                  P(J) = P(IMING)
                  P(IMING) = ITEMP
C
C                 SWAP ELEMENTS OF THE NEGATIVE GERSCHGORIN BOUNDS VECTOR
C
                  TEMP = G(J) 
                  G(J) = G(IMING)
                  G(IMING) = TEMP 
 
               END IF
C
C              CALCULATE DELTA AND ADD TO THE DIAGONAL.
C              DELTA=MAX{0,-A(J,J) + MAX{NORMJ,TAUGAM},DELTA_PREVIOUS}
C              WHERE NORMJ=SUM OF |A(I,J)|,FOR I=1,N, 
C              DELTA_PREVIOUS IS THE DELTA COMPUTED AT THE PREVIOUS ITERATION,
C              AND TAUGAM IS TAU1*GAMMA.
C

               NORMJ = 0.0
               DO 140 I = J+1, N
                  NORMJ = NORMJ + ABS(A(I,J))
 140           CONTINUE

               TEMP = MAX(NORMJ,TAUGAM)
               DELTA1 = TEMP - A(J,J)
               TEMP = 0.0
               DELTA1 = MAX(TEMP, DELTA1)
               DELTA = MAX(DELTA1,DELTA)     
               E(J) =  DELTA
               A(J,J) = A(J,J) + E(J)
C 
C              UPDATE THE GERSCHGORIN BOUND ESTIMATES
C              (NOTE: G(I) IS THE NEGATIVE OF THE 
C               GERSCHGORIN LOWER BOUND.)
C              
               IF (A(J,J) .NE. NORMJ) THEN
                  TEMP = (NORMJ/A(J,J)) - 1.0
 
                  DO 150 I = J+1, N
                     G(I) = G(I) + ABS(A(I,J)) * TEMP
 150              CONTINUE
 
               END IF
C
C              DO THE CHOLESKY UPDATE
C
               A(J,J) = SQRT(A(J,J))
               TEMPJJ = A(J,J)
               DO 160 I = J+1, N
                  A(I,J) = A(I,J) / TEMPJJ
 160           CONTINUE
               DO 180 I = J+1, N
                  TEMP = A(I,J)
                  DO 170 K = J+1, I
                     A(I,K) = A(I,K) - (TEMP * A(K,J))
 170              CONTINUE                               
 180           CONTINUE

            ELSE
   
               CALL FIN2X2(NDIM, N, A, E, J, TAU2, DELTA,GAMMA)

            END IF     

         END IF
   
 200   CONTINUE
   
      RETURN
      END
C************************************************************************
C       SUBROUTINE NAME : INIT
C
C       PURPOSE : SET UP FOR START OF CHOLESKY FACTORIZATION
C
C       INPUT : N, NDIM, A, TAU1
C
C       OUTPUT : PHASE1    - BOOLEAN VALUE SET TO TRUE IF IN PHASE ONE, 
C             OTHERWISE FALSE.
C      DELTA     - AMOUNT TO ADD TO AJJ AT ITERATION J
C      P,G,E - DESCRIBED ABOVE IN MODCHL
C      MING      - THE MINIMUM NEGATIVE GERSCHGORIN BOUND
C      GAMMA     - THE MAXIMUM DIAGONAL ELEMENT OF A
C      TAUGAM  - TAU1 * GAMMA
C
C************************************************************************
      SUBROUTINE INIT(N,NDIM,A,PHASE1,DELTA,P,G,E,MING,
     *                TAU1,GAMMA,TAUGAM)

      INTEGER N,NDIM
      DOUBLE PRECISION A(NDIM,N)
      LOGICAL PHASE1
      DOUBLE PRECISION DELTA,G(N),E(N)
      INTEGER P(N),I
      DOUBLE PRECISION MING,TAU1,GAMMA,TAUGAM
      INTRINSIC ABS, MAX


      PHASE1 = .TRUE.
      DELTA = 0.0
      MING = 0.0
      DO 10 I=1,N
         P(I)=I
         G(I)= 0.0
         E(I) = 0.0
 10   CONTINUE
   
C
C     FIND THE MAXIMUM MAGNITUDE OF THE DIAGONAL ELEMENTS.
C     IF ANY DIAGONAL ELEMENT IS NEGATIVE, THEN PHASE1 IS FALSE.
C
      GAMMA = 0.0
      DO 20 I=1,N
         GAMMA=MAX(GAMMA,ABS(A(I,I)))
         IF (A(I,I) .LT. 0.0) PHASE1 = .FALSE.
 20   CONTINUE
   
      TAUGAM = TAU1 * GAMMA

C
C     IF NOT IN PHASE1, THEN CALCULATE THE INITIAL GERSCHGORIN BOUNDS
C     NEEDED FOR THE START OF PHASE2.
C
      IF ( .NOT.PHASE1) CALL GERSCH(NDIM,N,A,1,G)
   
      RETURN 
      END
C************************************************************************
C
C       SUBROUTINE NAME : GERSCH
C
C       PURPOSE : CALCULATE THE NEGATIVE OF THE GERSCHGORIN BOUNDS
C                 CALLED ONCE AT THE START OF PHASE II.
C
C       INPUT   : NDIM, N, A, J
C
C       OUTPUT  : G - AN N VECTOR CONTAINING THE NEGATIVES OF THE
C           GERSCHGORIN BOUNDS.
C
C************************************************************************
      SUBROUTINE GERSCH(NDIM, N, A, J, G)

      INTEGER NDIM, N, J
      DOUBLE PRECISION A(NDIM,N), G(N)
 
      INTEGER I, K
      DOUBLE PRECISION OFFROW
      INTRINSIC ABS
 
      DO 30 I = J, N
         OFFROW = 0.0
         DO 10 K = J, I-1
            OFFROW = OFFROW + ABS(A(I,K))
 10      CONTINUE
         DO 20 K = I+1, N
            OFFROW = OFFROW + ABS(A(K,I))
 20      CONTINUE
            G(I) = OFFROW - A(I,I)
 30   CONTINUE

      RETURN
      END
C************************************************************************
C
C  SUBROUTINE NAME : FIN2X2
C
C  PURPOSE : HANDLES FINAL 2X2 SUBMATRIX IN PHASE II.
C            FINDS EIGENVALUES OF FINAL 2 BY 2 SUBMATRIX,
C            CALCULATES THE AMOUNT TO ADD TO THE DIAGONAL,
C            ADDS TO THE FINAL 2 DIAGONAL ELEMENTS, 
C            AND DOES THE FINAL UPDATE.
C
C  INPUT : NDIM, N, A, E, J, TAU2,
C          DELTA - AMOUNT ADDED TO THE DIAGONAL IN THE 
C                  PREVIOUS ITERATION
C
C  OUTPUT : A - MATRIX WITH COMPLETE L FACTOR IN THE LOWER TRIANGLE, 
C           E - N*1 VECTOR CONTAINING THE AMOUNT ADDED TO THE DIAGONAL 
C               AT EACH ITERATION,
C           DELTA - AMOUNT ADDED TO DIAGONAL ELEMENTS N-1 AND N.
C
C************************************************************************
      SUBROUTINE FIN2X2(NDIM, N, A, E, J, TAU2, DELTA,GAMMA) 

      INTEGER NDIM, N, J
      DOUBLE PRECISION A(NDIM,N), E(N), TAU2, DELTA,GAMMA

      DOUBLE PRECISION T1, T2, T3,LMBD1,LMBD2,LMBDHI,LMBDLO
      DOUBLE PRECISION DELTA1, TEMP,T1A,T2A
      INTRINSIC SQRT, MAX, MIN

C
C     FIND EIGENVALUES OF FINAL 2 BY 2 SUBMATRIX
C
      T1 = A(N-1,N-1) + A(N,N)
      T2 = A(N-1,N-1) - A(N,N) 
      T1A=ABS(T2)
      T2A= 2.D0 *  ABS(A(N,N-1))
      IF (T1A .GE. T2A) THEN
         IF (T1A .GT. 0) T2A = T2A / T1A
         T3 = T1A * SQRT(1.D0 + (T2A**2)) 
      ELSE
         T1A = T1A / T2A
         T3 = T2A * SQRT(1.D0 + (T1A**2))
      ENDIF
      LMBD1 = (T1 - T3)/2.
      LMBD2 = (T1 + T3)/2.
      LMBDHI = MAX(LMBD1,LMBD2)
      LMBDLO = MIN(LMBD1,LMBD2)
C
C     FIND DELTA SUCH THAT:
C     1.  THE L2 CONDITION NUMBER OF THE FINAL 
C     2X2 SUBMATRIX + DELTA*I <= TAU2 
C     2. DELTA >= PREVIOUS DELTA,
C     3. LMBDLO + DELTA >= TAU2 * GAMMA, 
C     WHERE LMBDLO IS THE SMALLEST EIGENVALUE OF THE FINAL 
C     2X2 SUBMATRIX
C

      DELTA1=(LMBDHI-LMBDLO)/(1.0-TAU2)
      DELTA1= MAX(DELTA1,GAMMA)
      DELTA1= TAU2 * DELTA1 - LMBDLO 
      TEMP = 0.0
      DELTA = MAX(DELTA, TEMP)
      DELTA = MAX(DELTA, DELTA1)

      IF (DELTA .GT. 0.0) THEN
         A(N-1,N-1) = A(N-1,N-1) + DELTA
         A(N,N) = A(N,N) + DELTA
         E(N-1) = DELTA
         E(N) = DELTA
      END IF
C
C     FINAL UPDATE
C
      A(N-1,N-1) = SQRT(A(N-1,N-1))
      A(N,N-1) = A(N,N-1)/A(N-1,N-1)
      A(N,N) = A(N,N) - (A(N,N-1)**2)
      A(N,N) = SQRT(A(N,N))

      RETURN
      END
C  ----------------------
C  |    S L V M D L     |
C  ----------------------     
      SUBROUTINE SLVMDL(NR,N,H,U,T,E,DIAG,S,G,
     Z                    PIVOT,W1,W2,W3,ALPHA,BETA,NOMIN,EPS)
      
C 
C PURPOSE:
C   COMPUTE TENSOR AND NEWTON STEPS
C
C----------------------------------------------------------------------------
C
C PARAMETERS:
C
C   NR            --> ROW DIMENSION OF MATRIX
C   N       --> DIMENSION OF PROBLEM
C   H(N,N)  --> HESSIAN
C   U(N)    --> VECTOR TO FORM Q IN QR
C   T(N)    --> WORKSPACE
C   E(N)    --> DIAGONAL ADDED TO HESSIAN IN CHOLESKY DECOMPOSITION
C   DIAG(N) --> DIAGONAL OF HESSIAN
C   S(N)    --> STEP TO PREVIOUS POINT (FOR TENSOR MODEL)
C   G(N)    --> CURRENT GRADIENT
C   PIVOT(N)      --> PIVOT VECTOR FOR CHOLESKY DECOMPOSITION
C   W1(N)      <--> ON INPUT: A=2*(GP-G-HS-S*BETA/(6*STS))
C               ON OUTPUT: TENSOR STEP
C   W2(N)   --> SH
C   W3(N)      <--  NEWTON STEP
C   ALPHA   --> SCALAR FOR 3RD ORDER TERM OF TENSOR MODEL
C   BETA    --> SCALAR FOR 4TH ORDER TERM OF TENSOR MODEL
C   NOMIN      <--  =.TRUE. IF TENSOR MODEL HAS NO MINIMIZER
C   EPS           --> MACHINE EPSILON
C
      INTEGER NR,N,PIVOT(N)
      DOUBLE PRECISION H(NR,N),U(N),T(N),E(N),DIAG(N),S(N),
     Z              G(N),W1(N),W2(N),W3(N),ALPHA,BETA,EPS
      INTEGER I,J
      DOUBLE PRECISION W11,W22,W33,SG,ADDMAX,SHS,CA,W12
      DOUBLE PRECISION W13,W23,SGSTAR,CB,CC,CD,R,R2,R1,TEMP
      DOUBLE PRECISION UU,SS
      LOGICAL NOMIN
C
C     S O L V E    M O D E L
C
      NOMIN=.FALSE.
C
C     COMPUTE QTHQ(N,N), ZTHZ(N-1,N-1) = FIRST N-1 ROWS AND N-1 
C     COLUMNS OF QTHQ

      IF (N.GT.1) THEN
      CALL ZHZ(NR,N,S,H,U,T)
	
C
C     IN CHOLESKY DECOMPOSITION WILL STORE H(1,1) ... H(N-1,N-1) 
C     IN DIAG(1) ... DIAG(N-1), STORE H(N,N) IN DIAG(N) FIRST
      DIAG(N)=H(N,N)
C
C     COLESKY DECOMPOSITION FOR FIRST N-1 ROWS AND N-1 COLUMNS OF ZTHZ
C     ZTHZ(N-1,N-1)=LLT
      CALL CHOLDR(NR,N-1,H,T,EPS,PIVOT,E,DIAG,ADDMAX)

      END IF
C
C     ON INPUT: SH IS STORED IN W2
      SHS=0D0
      DO 100 I=1,N
        SHS=SHS+W2(I)*S(I)
        W3(I)=G(I)
100   CONTINUE
C
C   COMPUTE W1,W2,W3
C   W1=L**-1*ZT*A
C   W2=L**-1*ZT*SH
C   W3=L**-1*ZT*G
C
      IF (N.GT.1) THEN

      CALL SOLVEW(NR,N,H,U,W1,T)
      CALL SOLVEW(NR,N,H,U,W2,T)
      CALL SOLVEW(NR,N,H,U,W3,T)

      END IF
C
C     COMPUTE COEFFICIENTS CA,CB,CC AND CD FOR REDUCED ONE VARIABLE
C     3RD ORDER EQUATION
      W11=0D0
      DO 110 I=1,N-1
        W11=W11+W1(I)*W1(I)
110   CONTINUE
      CA=BETA/6D0-W11/2D0
      W12=0D0
      DO 120 I=1,N-1
        W12=W12+W1(I)*W2(I)
120   CONTINUE
      CB=ALPHA/2D0-3D0*W12/2D0
      W13=0D0
      DO 130 I=1,N-1
        W13=W13+W1(I)*W3(I)
130   CONTINUE
      W22=0D0
      DO 133 I=1,N-1
        W22=W22+W2(I)*W2(I)
133   CONTINUE
      CC=SHS-W22-W13
      SG=0D0
      DO 140 I=1,N
        SG=SG+S(I)*G(I)
140   CONTINUE
      W23=0D0
      DO 145 I=1,N-1
        W23=W23+W2(I)*W3(I)
145   CONTINUE
      CD=SG-W23
      W33=0D0
      DO 147 I=1,N-1
        W33=W33+W3(I)*W3(I)
147   CONTINUE
C
C     COMPUTE DESIRABLE ROOT, SGSTAR, OF 3RD ORDER EQUATION
      IF(CA .NE. 0D0)THEN
        CALL SIGMA(SGSTAR,CA,CB,CC,CD)
        IF(CA .EQ. 0D0)THEN
          NOMIN=.TRUE.
          GO TO 200
        END IF
      ELSE
C       2ND ORDER ( CA=0 )
        IF(CB .NE. 0D0)THEN
          R=CC*CC-4D0*CB*CD
          IF(R .LT. 0D0)THEN
            NOMIN=.TRUE.
            GO TO 200
          ELSE
            R1=(-CC+SQRT(R))/(2D0*CB)
            R2=(-CC-SQRT(R))/(2D0*CB)
            IF(R2 .LT. R1)THEN
            TEMP=R1
            R1=R2
            R2=TEMP
            END IF
            IF(CB .GT. 0D0)THEN
            SGSTAR=R2
            ELSE
            SGSTAR=R1
            END IF
            IF( ( (R1 .GT. 0D0) .AND. (SGSTAR .EQ. R2) ) .OR.
     Z                ( (R2 .LT. 0D0) .AND. (SGSTAR .EQ. R1) ) )THEN
            NOMIN=.TRUE.
              GO TO 200
            END IF
          END IF
        ELSE
C         1ST ORDER (CA=0,CB=0)
          IF(CC .GT. 0D0)THEN
            SGSTAR=-CD/CC
          ELSE
            NOMIN=.TRUE.
            GO TO 200
          END IF
        END IF
      END IF
C
C     FIND TENSOR STEP, W1 (FUNCTION OF SGSTAR)
      CALL DSTAR(NR,N,U,S,W1,W2,W3,SGSTAR,H,W1)
C
C     COMPUTE DN
200   UU=0D0
      SS=0D0
      DO 202 I=1,N
        UU=UU+U(I)*U(I)
        SS=SS+S(I)*S(I)
202   CONTINUE
      UU=UU/2D0
      SS=DSQRT(SS)
      
      IF (N.EQ.1) THEN
        CALL CHOLDR(NR,N,H,T,EPS,PIVOT,E,DIAG,ADDMAX)
      ELSE
C
C COMPUTE LAST ROW OF L(N,N)
      DO 220 I=1,N-1
        TEMP=0D0
       IF(I .GT. 1)THEN
          DO 210 J=1,I-1
           TEMP=TEMP+H(N,J)*H(I,J)
210       CONTINUE
       END IF
       H(N,I)=(H(I,N)-TEMP)/H(I,I)
220   CONTINUE
      TEMP=0D0
      DO 224 I=1,N-1
        TEMP=TEMP+H(N,I)*H(N,I)
224   CONTINUE
      H(N,N)=DIAG(N)-TEMP+ADDMAX
      IF(H(N,N) .GT. 0D0)THEN
        H(N,N)=DSQRT(H(N,N))
      ELSE
C     AFTER ADDING THE LAST COLUMN AND ROW
C     QTHQ IS NOT P.D., NEED TO REDO CHOLESKY DECOMPOSITION
       DO 232 I=2,N
          DO 230 J=1,I-1
            H(I,J)=H(J,I)
230       CONTINUE
          H(I,I)=DIAG(I)
232     CONTINUE
        H(1,1)=DIAG(1)
        CALL CHOLDR(NR,N,H,T,EPS,PIVOT,E,DIAG,ADDMAX)
      END IF
      END IF
C
C   SOLVE QTHQ*QT*W3=-QT*G, WHERE W3 IS NEWTON STEP
C   W2=-QT*G
      DO 302 I=1,N
        W2(I)=0D0
        DO 300 J=1,N
          W2(I)=W2(I)+U(J)*U(I)*G(J)/UU
300     CONTINUE
        W2(I)=W2(I)-G(I)
302   CONTINUE
      CALL FORSLV(NR,N,H,W3,W2)
      CALL BAKSLV(NR,N,H,W2,W3)
C     W2=QT*W3 => W3=Q*W2 --- NEWTON STEP
      DO 312 I=1,N
        W3(I)=0D0
        DO 310 J=1,N
          W3(I)=W3(I)+U(I)*U(J)*W2(J)/UU
310     CONTINUE
        W3(I)=W2(I)-W3(I)
312   CONTINUE
      RETURN
      END
C  ----------------------
C  |  O P T S T P       |
C  ----------------------
      SUBROUTINE OPTSTP(N,XPLS,FPLS,GPLS,X,ITNCNT,ICSCMX,               
     +      ITRMCD,GRADTL,STEPTL,FSCALE,ITNLIM,IRETCD,MXTAKE,IPR,MSG,
     +      RGX,RSX)
C                                                                       
C UNCONSTRAINED MINIMIZATION STOPPING CRITERIA                          
C --------------------------------------------                          
C FIND WHETHER THE ALGORITHM SHOULD TERMINATE, DUE TO ANY               
C OF THE FOLLOWING:                                                     
C 1) PROBLEM SOLVED WITHIN USER TOLERANCE                               
C 2) CONVERGENCE WITHIN USER TOLERANCE                                  
C 3) ITERATION LIMIT REACHED                                            
C 4) DIVERGENCE OR TOO RESTRICTIVE MAXIMUM STEP (STEPMX) SUSPECTED      
C                                                                       
C                                                                       
C PARAMETERS                                                            
C ----------                                                            
C N            --> DIMENSION OF PROBLEM                                 
C XPLS(N)      --> NEW ITERATE X[K]                                     
C FPLS         --> FUNCTION VALUE AT NEW ITERATE F(XPLS)                
C GPLS(N)      --> GRADIENT AT NEW ITERATE, G(XPLS), OR APPROXIMATE     
C X(N)         --> OLD ITERATE X[K-1]                                   
C ITNCNT       --> CURRENT ITERATION K                                  
C ICSCMX      <--> NUMBER CONSECUTIVE STEPS .GE. STEPMX                 
C                  [RETAIN VALUE BETWEEN SUCCESSIVE CALLS]              
C ITRMCD      <--  TERMINATION CODE                                     
C GRADTL       --> TOLERANCE AT WHICH RELATIVE GRADIENT CONSIDERED CLOSE
C                  ENOUGH TO ZERO TO TERMINATE ALGORITHM                
C STEPTL       --> RELATIVE STEP SIZE AT WHICH SUCCESSIVE ITERATES      
C                  CONSIDERED CLOSE ENOUGH TO TERMINATE ALGORITHM       
C FSCALE       --> ESTIMATE OF SCALE OF OBJECTIVE FUNCTION              
C ITNLIM       --> MAXIMUM NUMBER OF ALLOWABLE ITERATIONS               
C IRETCD       --> RETURN CODE                                          
C MXTAKE       --> BOOLEAN FLAG INDICATING STEP OF MAXIMUM LENGTH USED  
C IPR          --> DEVICE TO WHICH TO SEND OUTPUT                       
C MSG         <--> CONTROL OUTPUT ON INPUT AND CONTAIN STOPPING
C                  CONDITION ON OUTPUT
C                                                                       
C                                                                       
      INTEGER N,ITNCNT,ICSCMX,ITRMCD,ITNLIM,IRETCD,IPR,MSG
      DOUBLE PRECISION XPLS(N),GPLS(N),X(N),FPLS,GRADTL,STEPTL,FSCALE
      INTEGER I,JTRMCD,IMSG
      DOUBLE PRECISION RGX,D,RELGRD,RELSTP,RSX
      LOGICAL MXTAKE                                                    
      INTRINSIC ABS, MAX
C                                                                       
      ITRMCD=0                                                          
      IMSG=MSG
      RGX=0.D0
      RSX=0.D0
C                                                                       
C LAST GLOBAL STEP FAILED TO LOCATE A POINT LOWER THAN X                
      IF(IRETCD.NE.1) GO TO 50                                          
C     IF(IRETCD.EQ.1)                                                   
C     THEN                                                              
        JTRMCD=3                                                        
        GO TO 600                                                       
C     ENDIF                                                             
   50 CONTINUE                                                          
C                                                                       
C FIND DIRECTION IN WHICH RELATIVE GRADIENT MAXIMUM.                    
C CHECK WHETHER WITHIN TOLERANCE                                        
C                                                                       
      D=MAX(ABS(FPLS),FSCALE)                                           
C     D=1D0
      RGX=0.0                                                           
      DO 100 I=1,N                                                      
        RELGRD=ABS(GPLS(I))*MAX(ABS(XPLS(I)),1.D0)/D                      
        RGX=MAX(RGX,RELGRD)                                             
  100 CONTINUE                                                          
      JTRMCD=1                                                          
      IF(RGX.LE.GRADTL) GO TO 600                                       
C                                                                       
      IF(ITNCNT.EQ.0) RETURN                                            
C                                                                       
C FIND DIRECTION IN WHICH RELATIVE STEPSIZE MAXIMUM                     
C CHECK WHETHER WITHIN TOLERANCE.                                       
C                                                                       
      RSX=0.0                                                           
      DO 120 I=1,N                                                      
        RELSTP=ABS(XPLS(I)-X(I))/MAX(ABS(XPLS(I)),1.D0)                   
        RSX=MAX(RSX,RELSTP)                                             
  120 CONTINUE                                                          
      JTRMCD=2                                                          
      IF(RSX.LE.STEPTL) GO TO 600                                       
C                                                                       
C CHECK ITERATION LIMIT                                                 
C                                                                       
      JTRMCD=4                                                          
      IF(ITNCNT.GE.ITNLIM) GO TO 600                                    
C                                                                       
C CHECK NUMBER OF CONSECUTIVE STEPS \ STEPMX                            
C                                                                       
      IF(MXTAKE) GO TO 140                                              
C     IF(.NOT.MXTAKE)                                                   
C     THEN                                                              
        ICSCMX=0                                                        
        RETURN                                                          
C     ELSE                                                              
  140   CONTINUE                                                        
C       IF (MOD(MSG/8,2) .EQ. 0) WRITE(IPR,900)
      IF(IMSG .GE. 1) WRITE(IPR,900)
        ICSCMX=ICSCMX+1                                                 
        IF(ICSCMX.LT.5) RETURN                                          
        JTRMCD=5                                                        
C     ENDIF                                                             
C                                                                       
C                                                                       
C PRINT TERMINATION CODE                                                
C                                                                       
  600 ITRMCD=JTRMCD                                                     
C     IF (MOD(MSG/8,2) .EQ. 0) GO TO(601,602,603,604,605), ITRMCD
      IF (IMSG .GE. 1) GO TO(601,602,603,604,605), ITRMCD
      GO TO 700
  601 WRITE(IPR,901)                                                    
      GO TO 700                                                         
  602 WRITE(IPR,902)                                                    
      GO TO 700                                                         
  603 WRITE(IPR,903)                                                    
      GO TO 700                                                         
  604 WRITE(IPR,904)                                                    
      GO TO 700                                                         
  605 WRITE(IPR,905)                                                    
C                                                                       
700   MSG=-ITRMCD
      RETURN                                                            
C                                                                       
  900 FORMAT(48H OPTSTP    STEP OF MAXIMUM LENGTH (STEPMX) TAKEN)       
  901 FORMAT(' OPTSTP    RELATIVE GRADIENT CLOSE TO ZERO.'/             
     +       ' OPTSTP    CURRENT ITERATE IS PROBABLY SOLUTION.')        
  902 FORMAT(48H OPTSTP    SUCCESSIVE ITERATES WITHIN TOLERANCE./       
     +       48H OPTSTP    CURRENT ITERATE IS PROBABLY SOLUTION.)       
  903 FORMAT(52H OPTSTP    LAST GLOBAL STEP FAILED TO LOCATE A POINT,   
     +       14H LOWER THAN X./                                         
     +       51H OPTSTP    EITHER X IS AN APPROXIMATE LOCAL MINIMUM,    
     +       17H OF THE FUNCTION,/                                      
     +       50H OPTSTP    THE FUNCTION IS TOO NON-LINEAR FOR THIS,     
     +       11H ALGORITHM,/                                            
     +       34H OPTSTP    OR STEPTL IS TOO LARGE.)                     
  904 FORMAT(36H OPTSTP    ITERATION LIMIT EXCEEDED./                   
     +       28H OPTSTP    ALGORITHM FAILED.)                           
  905 FORMAT(39H OPTSTP    MAXIMUM STEP SIZE EXCEEDED 5,                
     +       19H CONSECUTIVE TIMES./                                    
     +       50H OPTSTP    EITHER THE FUNCTION IS UNBOUNDED BELOW,/     
     +       47H OPTSTP    BECOMES ASYMPTOTIC TO A FINITE VALUE,        
     +       30H FROM ABOVE IN SOME DIRECTION,/                         
     +       33H OPTSTP    OR STEPMX IS TOO SMALL)                      
      END 
C                                                              
      SUBROUTINE  DCOPY(N,DX,INCX,DY,INCY)
C
C     COPIES A VECTOR, X, TO A VECTOR, Y.
C     USES UNROLLED LOOPS FOR INCREMENTS EQUAL TO ONE.
C     JACK DONGARRA, LINPACK, 3/11/78.
C
      DOUBLE PRECISION DX(*),DY(*)
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
        DY(IY) = DX(IX)
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
   20 M = MOD(N,7)
      IF( M .EQ. 0 ) GO TO 40
      DO 30 I = 1,M
        DY(I) = DX(I)
   30 CONTINUE
      IF( N .LT. 7 ) RETURN
   40 MP1 = M + 1
      DO 50 I = MP1,N,7
        DY(I) = DX(I)
        DY(I + 1) = DX(I + 1)
        DY(I + 2) = DX(I + 2)
        DY(I + 3) = DX(I + 3)
        DY(I + 4) = DX(I + 4)
        DY(I + 5) = DX(I + 5)
        DY(I + 6) = DX(I + 6)
   50 CONTINUE
      RETURN
      END
C
      DOUBLE PRECISION FUNCTION DDOT(N,DX,INCX,DY,INCY)
C
C     FORMS THE DOT PRODUCT OF TWO VECTORS.
C     USES UNROLLED LOOPS FOR INCREMENTS EQUAL TO ONE.
C     JACK DONGARRA, LINPACK, 3/11/78.
C
      DOUBLE PRECISION DX(*),DY(*),DTEMP
      INTEGER I,INCX,INCY,IX,IY,M,MP1,N
C
      DDOT = 0.0D0
      DTEMP = 0.0D0
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
        DTEMP = DTEMP + DX(IX)*DY(IY)
        IX = IX + INCX
        IY = IY + INCY
   10 CONTINUE
      DDOT = DTEMP
      RETURN
C
C        CODE FOR BOTH INCREMENTS EQUAL TO 1
C
C
C        CLEAN-UP LOOP
C
   20 M = MOD(N,5)
      IF( M .EQ. 0 ) GO TO 40
      DO 30 I = 1,M
        DTEMP = DTEMP + DX(I)*DY(I)
   30 CONTINUE
      IF( N .LT. 5 ) GO TO 60
   40 MP1 = M + 1
      DO 50 I = MP1,N,5
        DTEMP = DTEMP + DX(I)*DY(I) + DX(I + 1)*DY(I + 1) +
     *   DX(I + 2)*DY(I + 2) + DX(I + 3)*DY(I + 3) + DX(I + 4)*DY(I + 4)
   50 CONTINUE
   60 DDOT = DTEMP
      RETURN
      END
C
      SUBROUTINE  DSCAL(N,DA,DX,INCX)
C
C     SCALES A VECTOR BY A CONSTANT.
C     USES UNROLLED LOOPS FOR INCREMENT EQUAL TO ONE.
C     JACK DONGARRA, LINPACK, 3/11/78.
C
      DOUBLE PRECISION DA,DX(*)
      INTEGER I,INCX,M,MP1,N,NINCX
C
      IF(N.LE.0)RETURN
      IF(INCX.EQ.1)GO TO 20
C
C        CODE FOR INCREMENT NOT EQUAL TO 1
C
      NINCX = N*INCX
      DO 10 I = 1,NINCX,INCX
        DX(I) = DA*DX(I)
   10 CONTINUE
      RETURN
C
C        CODE FOR INCREMENT EQUAL TO 1
C
C
C        CLEAN-UP LOOP
C
   20 M = MOD(N,5)
      IF( M .EQ. 0 ) GO TO 40
      DO 30 I = 1,M
        DX(I) = DA*DX(I)
   30 CONTINUE
      IF( N .LT. 5 ) RETURN
   40 MP1 = M + 1
      DO 50 I = MP1,N,5
        DX(I) = DA*DX(I)
        DX(I + 1) = DA*DX(I + 1)
        DX(I + 2) = DA*DX(I + 2)
        DX(I + 3) = DA*DX(I + 3)
        DX(I + 4) = DA*DX(I + 4)
   50 CONTINUE
      RETURN
      END

