      PROGRAM    continuation_lines
         IMPLICIT   NONE
!        [specification part]
!        [execution part]
      ! In Fortran, a statement must start on a new line. If a statement is 
      ! too long to fit on a line, it can be continued with the following methods:

      ! If a line is ended with an ampersand, &, it will be continued on the next line.
      ! Continuation is normally to the first character of the next non-comment line.

          A = 174.5 * Year   &
              + Count / 100

      ! The above is equivalent to the following

          A = 174.5 * Year  + Count / 100

      ! Note that & is not part of the statement.

          A = 174.5 * Year   &
          !  this is a comment line
              + Count / 100

      ! The above is equivalent to the following, since the comment is 
      ! ignored by the compiler:

          A = 174.5 * Year  + Count / 100

      ! If the first non-blank character of the continuation line is &, 
      ! continuation is to the first character after the &:

          A = 174.5 + ThisIsALong&
               &VariableName * 123.45

      ! is equivalent to

          A = 174.5 + ThisIsALongVariableName * 123.45

      ! In this case, there should be no spaces between the last character and 
      ! the & on the first line. For example,

          A = 174.5 + ThisIsALong   &
               &VariableName * 123.45

      ! is equivalent to

          A = 174.5 + ThisIsALong   VariableName * 123.45

      ! Note that there are spaces between ThisIsALong and VariableName. In 
      ! this way, a token (name and number) can be split over two lines. 
      ! However, this is not recommended
!        [subprogram part]
      END PROGRAM continuation_lines


