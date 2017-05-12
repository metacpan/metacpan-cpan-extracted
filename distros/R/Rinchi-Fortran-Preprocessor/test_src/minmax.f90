! ------------------------------------------------------
! This program reads in a number of integer input until
! a negative one, and determines the minimum and maximum
! of the input data values.
! ------------------------------------------------------

PROGRAM  MinMax
   IMPLICIT  NONE

   INTEGER :: Minimum, Maximum          ! max and min
   INTEGER :: Count                     ! # of data items
   INTEGER :: Input                     ! the input value

   Count = 0                            ! initialize counter
   DO                                   ! for each iteration
      READ(*,*) Input                   !   read in a new input
      IF (Input < 0)  EXIT              !   if it is < 0, done.
      Count = Count + 1                 !   if >= 0, increase counter
      WRITE(*,*)  'Data item #', Count, ' = ', Input
      IF (Count == 1) THEN              !   is this the 1st data?
         Maximum = Input                !     yes, assume it is the
         Minimum = Input                !     min and the max
      ELSE                              !   no, not the 1st data
         IF (Input > Maximum)  Maximum = Input    ! compare against the
         IF (Input < Minimum)  Minimum = Input    ! existing min & max
      END IF
   END DO

   WRITE(*,*)
   IF (Count > 0) THEN                  ! if at one data item found
      WRITE(*,*)  'Found ', Count, ' data items'
      WRITE(*,*)  '  Maximum = ', Maximum
      WRITE(*,*)  '  Minimum = ', Minimum
   ELSE
      WRITE(*,*)  'No data item found.' ! no data item found
   END IF

END PROGRAM  MinMax
