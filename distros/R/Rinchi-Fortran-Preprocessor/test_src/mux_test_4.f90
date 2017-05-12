      PROGRAM  MuxTest
        IMPLICIT  NONE

        INTEGER(4), PARAMETER :: SEND_RECV = 1
        INTEGER(4), PARAMETER :: TSUB_ADDR = 16
        INTEGER(4), PARAMETER :: WORD_CT   = 20
        INTEGER(4), PARAMETER :: RT_UP     = 31
        INTEGER(4), PARAMETER :: TERM_ADDR = 28

        CALL SomeRoutine(TERM_ADDR, SEND_RECV, TSUB_ADDR, WORD_CT, RT_UP)
!        CALL SomeRoutine(28, 1, 16, 20, 31)

     END PROGRAM  MuxTest
