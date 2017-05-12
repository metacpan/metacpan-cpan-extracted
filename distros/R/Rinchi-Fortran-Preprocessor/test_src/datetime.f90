! ----------------------------------------------------------------
!  This program uses DATE_AND_TIME() to retrieve the system date
!  and the system time.  Then, it converts the date and time
!  information to a readable format.  This program demonstrates
!  the use of concatenation operator // and substring
! ----------------------------------------------------------------

PROGRAM  DateTime
   IMPLICIT   NONE

   CHARACTER(LEN = 8)  :: DateINFO                 ! ccyymmdd
   CHARACTER(LEN = 4)  :: Year, Month*2, Day*2

   CHARACTER(LEN = 10) :: TimeINFO, PrettyTime*12  ! hhmmss.sss
   CHARACTER(LEN = 2)  :: Hour, Minute, Second*6

   CALL  DATE_AND_TIME(DateINFO, TimeINFO)

!  decompose DateINFO into year, month and day.
!  DateINFO has a form of ccyymmdd, where cc = century, yy = year
!  mm = month and dd = day

   Year  = DateINFO(1:4)
   Month = DateINFO(5:6)
   Day   = DateINFO(7:8)

   WRITE(*,*)  'Date information -> ', DateINFO
   WRITE(*,*)  '            Year -> ', Year
   WRITE(*,*)  '           Month -> ', Month
   WRITE(*,*)  '             Day -> ', Day

!  decompose TimeINFO into hour, minute and second.
!  TimeINFO has a form of hhmmss.sss, where h = hour, m = minute
!  and s = second

   Hour   = TimeINFO(1:2)
   Minute = TimeINFO(3:4)
   Second = TimeINFO(5:10)

   PrettyTime = Hour // ':' // Minute // ':' // Second

   WRITE(*,*)
   WRITE(*,*)  'Time Information -> ', TimeINFO
   WRITE(*,*)  '            Hour -> ', Hour
   WRITE(*,*)  '          Minite -> ', Minute
   WRITE(*,*)  '          Second -> ', Second
   WRITE(*,*)  '     Pretty Time -> ', PrettyTime

!  the substring operator can be used on the left-hand side.
 
   PrettyTime = ' '
   PrettyTime( :2) = Hour
   PrettyTime(3:3) = ':'
   PrettyTime(4:5) = Minute
   PrettyTime(6:6) = ':'
   PrettyTime(7: ) = Second

   WRITE(*,*)
   WRITE(*,*)  '     Pretty Time -> ', PrettyTime 

END PROGRAM  DateTime
