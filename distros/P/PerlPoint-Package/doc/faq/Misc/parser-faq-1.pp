
=Variable assignments do not work

\BU<Question:>

I wrote a paragraph like

  $var = 120

to assign \C<120> to \C<$var>, but when I used it like in

  The variable was set to $var.

\C<$var> was not replaced by the value.


\BU<Answer:>

Just remove the spaces around the "=":

  $var=120


\BU<Discussion:>

Because \B<PerlPoint::Parser> has to recognize PerlPoint controls amidst natural language it cannot handle whitespaces as
programming language parsers do - whitespaces are real tokens. Not accepting them in an assignment simplifies the parsers
paragraph type detection.

