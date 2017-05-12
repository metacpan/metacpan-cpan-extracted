! --------------------------------------------------------------------
! PROGRAM  TableLookUp
!    Given an array and a input value, this program can determine if 
! the value if in the table.  If it is, the array location where the 
! value is stored is returned.  Binary search is used.
! --------------------------------------------------------------------

PROGRAM  TableLookUp
   IMPLICIT  NONE
   INTEGER, PARAMETER              :: TableSize = 100
   INTEGER, DIMENSION(1:TableSize) :: Table
   INTEGER                         :: ActualSize
   INTEGER                         :: Key
   INTEGER                         :: Location
   INTEGER                         :: i
   INTEGER                         :: end_of_input

   READ(*,*)  ActualSize                ! read in the actual size and table
   READ(*,*)  (Table(i), i = 1, ActualSize)
   WRITE(*,*) "Input Table:"
   WRITE(*,*) (Table(i), i = 1, ActualSize)
   WRITE(*,*)
   DO                                   ! keep reading in a key value
      WRITE(*,*)  "A search key please --> "
      READ(*,*,IOSTAT=end_of_input)  Key
      IF (end_of_input < 0)  EXIT       ! EXIT of end-of-file reached
      Location = LookUp(Table, ActualSize, Key)   ! do a table look up
      IF (Location > 0) THEN            ! display the search result
         WRITE(*,*)  "Key value ", Key, " appears in location ", Location
      ELSE
         WRITE(*,*)  "Key value ", Key, " is not found"
      END IF
   END DO
   WRITE(*,*)
   WRITE(*,*) "Table lookup operation completes"

CONTAINS

! --------------------------------------------------------------------
! INTEGER FUNCTION  LookUp():
!    Given an array x() and a key value Data, this function determines
! if Data is a member of x().  If it is, the index where Data can be 
! found is returned; otherwise, it returns 0.
! --------------------------------------------------------------------

   INTEGER FUNCTION  LookUp(x, Size, Data)
      IMPLICIT  NONE
      INTEGER, DIMENSION(1:), INTENT(IN) :: x
      INTEGER, INTENT(IN)                :: Size
      INTEGER, INTENT(IN)                :: Data
      INTEGER                            :: Left, Right, Mid

      LookUp = 0                        ! assume not found
      Left  = 1 			! left end
      Right = Size			! right end
      DO				! loop until done
         IF (Left > Right)  EXIT	! if left and right cross, exit
         Mid = (Left + Right) / 2	! get the midpoint
         IF (Data == x(Mid)) THEN	! is input = to the midpoint
            LookUp = Mid		! Yes, record the position
            EXIT			! and exit
         ELSE IF (Data < x(Mid)) THEN	! is Data < midpoint?
            Right = Mid - 1		! YES, ignore the right half
         ELSE
            Left  = Mid + 1		! otherwise, ignore the left half
         END IF
      END DO				! go back and try again
   END FUNCTION  LookUp

END PROGRAM  TableLookUp
