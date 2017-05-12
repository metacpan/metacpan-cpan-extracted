PROGRAM  LogFunction
   IMPLICIT   NONE
   REAL, PARAMETER   :: Initial =  2.0
   REAL, PARAMETER   :: Final   =  0.0
   REAL, PARAMETER   :: Step    = -0.2
   REAL              :: x
   INTEGER           :: Count
   CHARACTER(LEN=80) :: FMT

   FMT   = "(I3, F10.5, E15.5, E15.5E3, ES15.5, EN15.5)"
   Count = 1
   x     = Initial
   DO
      IF (x <= Final)  EXIT
      WRITE(*,FMT)     Count, x, LOG(x), LOG(x), LOG(x), LOG(x)
      x     = x + Step
      Count = Count + 1
   END DO
END PROGRAM  LogFunction
