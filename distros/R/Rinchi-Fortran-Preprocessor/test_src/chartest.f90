! ------------------------------------------------------------
! This program reads in a single character and determines if
! it is a vowel, a consonant, a digit, one of the four 
! arithmetic operators (+, -, * and /), a space, or something
! else.  You can do it with IF-THEN-ELSE-END IF statement; but
! SELECT CASE statement provides a cleaner solution.
!
! For character input, you could use the quote characters like
!         'G'  
! Or, just type the character.  In this case, the first 
! character you type will be read.
! ------------------------------------------------------------

PROGRAM  CharacterTesting
   IMPLICIT  NONE

   CHARACTER(LEN=1) :: Input

   READ(*,*)  Input

   SELECT CASE (Input)
      CASE ('A' : 'Z', 'a' : 'z')       ! rule out letters
         WRITE(*,*)  'A letter is found : "', Input, '"'
         SELECT CASE (Input)            ! a vowel ?
            CASE ('A', 'E', 'I', 'O', 'U', 'a', 'e', 'i', 'o','u')
               WRITE(*,*)  'It is a vowel'
            CASE DEFAULT                ! it must be a consonant
               WRITE(*,*)  'It is a consonant'
         END SELECT
      CASE ('0' : '9')                  ! a digit
         WRITE(*,*)  'A digit is found : "', Input, '"'
      CASE ('+', '-', '*', '/')         ! an operator
         WRITE(*,*)  'An operator is found : "', Input, '"'
      CASE (' ')                        ! space
         WRITE(*,*)  'A space is found : "', Input, '"'
      CASE DEFAULT                      ! something else
         WRITE(*,*)  'Something else found : "', Input, '"'
   END SELECT

END PROGRAM  CharacterTesting
