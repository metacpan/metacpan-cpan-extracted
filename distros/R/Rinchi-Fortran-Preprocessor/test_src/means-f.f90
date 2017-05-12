PROGRAM  Means
   IMPLICIT  NONE
   REAL                        :: a, b, c
   REAL                        :: Am, Gm, Hm
   CHARACTER(LEN=*), PARAMETER :: FMT = "(1X, A//3(1X, A, F15.7/))"

   READ(*,*) a, b, c
   Am = (a + b + c)/3.0
   Gm = (a * b * c)**(1.0/3.0)
   Hm = 3.0 / (1.0/a + 1.0/b + 1.0/c)
   WRITE(*,FMT) "Input Data",   &
                "a = ", a,      &
                "b = ", b,      &
                "c = ", c
   WRITE(*,FMT) "Computed Results",  &
                "Arithmetic Mean = ", Am, &
                "Geometric Mean  = ", Gm, &
                "Harmonic Mean   = ", Hm

END PROGRAM  Means
