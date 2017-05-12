
// vim: set filetype=PerlPoint:


=Colors in Tables

\QST

How can I use \X<color in tables>?

\ANS

Use the \C<\\TABLE> tag with special options: 

 \\TABLE{separator="," \B<bgcolor>="#CCCCCC" \B<head_bgcolor>=yellow}
   Column 1 , Column 2
   value 1  , value 2
   value 3 , value 4
 \\END_TABLE

\DSC

The above examples yields:

\TABLE{separator="," bgcolor="#CCCCCC" head_bgcolor=yellow}
Column 1 , Column 2
value 1  , value 2
value 3 , value 4
\END_TABLE





